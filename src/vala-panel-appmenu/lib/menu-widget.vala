/*
 * vala-panel-appmenu
 * Copyright (C) 2015 Konstantin Pugin <ria.freelander@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;

namespace Key
{
    public const string COMPACT_MODE = "compact-mode";
    public const string BOLD_APPLICATION_NAME = "bold-application-name";
    public const string ELLIPSIS_MODE = "ellipsis-mode";
    public const string HEXPAND = "hexpand";
}

namespace Appmenu
{
    public class MenuWidget: Gtk.Bin
    {
        public bool compact_mode {get; set; default = false;}
        public bool bold_application_name {get; set; default = true;}
        public bool ellipsis_mode {get; set; default = false;}
        private Gtk.Adjustment? scroll_adj = null;
        public Gtk.ScrolledWindow? scroller = null;
        private Gtk.CssProvider provider;
        private GLib.MenuModel? appmenu = null;
        private GLib.MenuModel? menubar = null;
        private weak GLib.MenuModel? barToTrim = null;
        private Backend backend = new BackendImpl();
        public Gtk.MenuBar mwidget = new Gtk.MenuBar();
        private ulong backend_connector = 0;
        private ulong compact_connector = 0;
        private ulong size_connector = 0;
        //  private File file = File.new_for_path("/home/tubext/Patches/vala-panel-appmenu-xfce-git/log.txt");
        //  private DataOutputStream? stream = null;
        private uint leave_id = 0;
        construct
        {
            //  stream = new DataOutputStream(file.append_to(FileCreateFlags.REPLACE_DESTINATION));
            provider = new Gtk.CssProvider();
            provider.load_from_resource("/org/vala-panel/appmenu/appmenu.css");
            unowned Gtk.StyleContext context = this.get_style_context();
            context.add_class("-vala-panel-appmenu-core");
            unowned Gtk.StyleContext mcontext = mwidget.get_style_context();
            Signal.connect(this,"notify",(GLib.Callback)restock,null);
            backend_connector = backend.active_model_changed.connect(()=>{
                Timeout.add(50,()=>{
                    backend.set_active_window_menu(this);
                    return Source.REMOVE;
                });
            });
            mcontext.add_class("-vala-panel-appmenu-private");
            Gtk.StyleContext.add_provider_for_screen(this.get_screen(), provider,Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            mwidget.hexpand = false;
            mwidget.vexpand = true;
            mwidget.halign = Gtk.Align.START;
            //Setup menubar
            scroll_adj = new Gtk.Adjustment(0, 0, 0, 20, 20, 0);
            scroller = new Gtk.ScrolledWindow(scroll_adj, null);
            //  scroller.set_hexpand(this.hexpand);
            //  scroller.set_vexpand(true);
            scroller.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.NEVER);
            scroller.set_shadow_type(Gtk.ShadowType.NONE);
            scroller.scroll_event.connect(on_scroll_event);
            scroller.set_min_content_width(16);
            scroller.set_min_content_height(16);
            scroller.set_propagate_natural_height(true);
            scroller.set_propagate_natural_width(true);
            this.add(scroller);
            scroller.add(mwidget);
            mwidget.show();
           
            scroller.show();
            this.show();

            //  var enterred = false;
            mwidget.enter_notify_event.connect((enter_event)=>{
                //  switch (enter_event.detail) {
                //      case Gdk.NotifyType.INFERIOR:
                //      stream.put_string("ENTER INFERIOR\n");
                //          break;
                //      case Gdk.NotifyType.ANCESTOR:
                //      stream.put_string("ENTER ANCESTOR\n");
                //          break;
                //      case Gdk.NotifyType.VIRTUAL:
                //      stream.put_string("ENTER VIRTUAL\n");
                //          break;
                //      case Gdk.NotifyType.NONLINEAR:
                //      stream.put_string("ENTER NONLINEAR\n");
                //          break;
                //      case Gdk.NotifyType.NONLINEAR_VIRTUAL:
                //      stream.put_string("ENTER NONLINEAR_VIRTUAL\n");
                //          break;
                //  }
                if (leave_id != 0) {
                    Source.remove(leave_id);
                    leave_id = 0;
                }
                if (enter_event.detail != Gdk.NotifyType.VIRTUAL && enter_event.detail != Gdk.NotifyType.NONLINEAR_VIRTUAL) return false;
                if (mwidget.get_selected_item() != null) { return false; }
                mwidget.select_first(true);
                return false;
            });
            mwidget.leave_notify_event.connect((e)=>{
                leave_id = Timeout.add(1000, ()=>{
                    if (leave_id == 0) {return false;}
                    var display = Gdk.Display.get_default();
                    var seat = display.get_default_seat();
                    int x = -1;
                    int y = -1;
                    mwidget.get_window().get_device_position(seat.get_pointer(), out x, out y, null);
                    Gtk.Allocation? a = null;
                    mwidget.get_allocation(out a);
                    //  stream.put_string(x.to_string() + "," + y.to_string() + "," + a.width.to_string() + "," + a.height.to_string() + "\n");
                    if (x > 0 && x < a.width && y > 0 && y < a.height) {
                        leave_id = 0;
                        return false;
                    };
                    mwidget.deselect();
                    leave_id = 0;
                    return false;
                });
                //  
                //  mwidget.deselect();
                return false;
            });
            //  mwidget.leave_notify_event.connect((leave_event)=>{
            //      int? x = null;
            //      int? y = null;
            //      mwidget.get_pointer(out x, out y);
            //      if (x == null || y == null) 
            //          enterred = false;
            //      return false;
            //  });
        }
        public MenuWidget()
        {
            Object();
        }
        private void restock()
        {
            unowned Gtk.StyleContext mcontext = mwidget.get_style_context();
            if(bold_application_name)
                mcontext.add_class("-vala-panel-appmenu-bold");
            else
                mcontext.remove_class("-vala-panel-appmenu-bold");
            var menu = new GLib.Menu();
            if (this.appmenu != null)
                menu.append_section(null,this.appmenu);

            int items = -1;
            if (this.menubar != null) {
                items = this.menubar.get_n_items();
                if (this.ellipsis_mode) {
                    trim_memu(this.menubar, menu);
                } else {
                    menu.append_section(null, this.menubar);
                }
            }
            

            if (this.compact_mode && items == 0)
            {
                compact_connector = this.menubar.items_changed.connect((a,b,c)=>{
                    restock();
                });
            }
            if (this.compact_mode && items > 0)
            {
                if(compact_connector > 0)
                {
                    this.menubar.disconnect(compact_connector);
                    compact_connector = 0;
                }
                var compact = new GLib.Menu();
                string? name = null;
                if(this.appmenu != null)
                    this.appmenu.get_item_attribute(0,"label","s",&name);
                else
                    name = GLib.dgettext(Config.GETTEXT_PACKAGE,"Compact Menu");
                compact.append_submenu(name,menu);
                mwidget.bind_model(compact,null,true);
            }
            else
                mwidget.bind_model(menu,null,true);
        }
        private void trim_memu(GLib.MenuModel _barToTrim, GLib.Menu menu)
        {
            var _count = _barToTrim.get_n_items();
            while (_count == 1) {
                var link = _barToTrim.get_item_link(0, "section");
                if (link == null) break;
                _barToTrim = link;
                _count = link.get_n_items();
            }
            if (size_connector != 0 && this.barToTrim != null) {
                this.barToTrim.disconnect(size_connector);
            }
            size_connector = _barToTrim.items_changed.connect((a, b, c) => {
                trim_memu(_barToTrim, menu);
            });
            this.barToTrim = _barToTrim;
            if (_count > 5) {
                if (menu.get_n_items() == 2) menu.remove(1);
                var trimmed = new GLib.Menu();
                for (var i = 0; i < 4; ++i) {
                    var item = new GLib.MenuItem.from_model(_barToTrim, i);
                    trimmed.append_item(item);
                }
                var rest = new GLib.Menu();
                for (var i = 4; i < _count; ++i) {
                    var item = new GLib.MenuItem.from_model(_barToTrim, i);
                    string? label = null;
                    item.get_attribute("label", "s", &label);
                    if (label == null || label.length == 0) {
                        GLib.HashTable<string, GLib.MenuModel>? links = null;
                        _barToTrim.get_item_links(i, out links);
                        links.for_each((key, value)=> {
                            if (key == "section") rest.append_section(null, value);
                        });
                        continue;
                    }
                    rest.append_item(item);
                }

                var item = new GLib.MenuItem.submenu("⋯", rest);
                trimmed.append_item(item);
                menu.append_section(null, trimmed);
            }
            else if (menu.get_n_items() == 1) {
                menu.append_section(null, _barToTrim);
            }
        }
        public void set_appmenu(GLib.MenuModel? appmenu_model)
        {
            this.appmenu = appmenu_model;
            this.restock();
        }
        public void set_menubar(GLib.MenuModel? menubar_model)
        {
            this.menubar = menubar_model;
            this.restock();
        }
        protected bool on_scroll_event(Gtk.Widget w, Gdk.EventScroll event)
        {
            var val = scroll_adj.get_value();
            var incr = scroll_adj.get_step_increment();
            if (event.direction == Gdk.ScrollDirection.UP)
            {
                scroll_adj.set_value(val - incr);
                return true;
            }
            if (event.direction == Gdk.ScrollDirection.DOWN)
            {
                scroll_adj.set_value(val + incr);
                return true;
            }
            if (event.direction == Gdk.ScrollDirection.LEFT)
            {
                scroll_adj.set_value(val - incr);
                return true;
            }
            if (event.direction == Gdk.ScrollDirection.RIGHT)
            {
                scroll_adj.set_value(val + incr);
                return true;
            }
            if (event.direction == Gdk.ScrollDirection.SMOOTH)
            {
                scroll_adj.set_value(val + incr * (event.delta_y + event.delta_x));
                return true;
            }
            return false;
        }
        protected override void map()
        {
            base.map();
            unowned Gtk.Settings gtksettings = this.get_settings();
            gtksettings.gtk_shell_shows_app_menu = false;
            gtksettings.gtk_shell_shows_menubar = false;
        }
    }
}
