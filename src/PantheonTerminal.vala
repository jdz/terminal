// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2012 Mario Guerriero <mefrio.g@gmail.com>
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

using Gtk;

using Granite;
using Granite.Services;

using PantheonTerminal;

namespace PantheonTerminal {

    public class PantheonTerminalApp : Granite.Application {

        public GLib.List <PantheonTerminalWindow> windows;

        static string app_cmd_name;
        static string app_shell_name;

        /* command_x (-x) is used for running commands independently (not inside a shell) */
        [CCode (array_length = false, array_null_terminated = true)]
        static string[]? command_x = null;

        /* command_e (-e) is used for running commands in a shell */
        [CCode (array_length = false, array_null_terminated = true)]
        static string[]? command_e = null;

        static bool print_version;

        public int minimum_width;
        public int minimum_height;

        construct {
            print_version = false;
            build_data_dir = Constants.DATADIR;
            build_pkg_data_dir = Constants.PKGDATADIR;
            build_release_name = Constants.RELEASE_NAME;
            build_version = Constants.VERSION;
            build_version_info = Constants.VERSION_INFO;

            program_name = app_cmd_name;
            exec_name = app_cmd_name.down ().replace (" ", "-");
            app_years = "2011-2012";
            app_icon = "utilities-terminal";
            app_launcher = "pantheon-terminal.desktop";
            application_id = "net.launchpad.pantheon-terminal";
            main_url = "https://launchpad.net/pantheon-terminal";
            bug_url = "https://bugs.launchpad.net/pantheon-terminal";
            help_url = "https://answers.launchpad.net/pantheon-terminal";
            translate_url = "https://translations.launchpad.net/pantheon-terminal";
            about_authors = { "David Gomes <david@elementaryos.org",
                              "Mario Guerriero <mefrio@elementaryos.org>",
                              "Akshay Shekher <voldyman666@gmail.com>" };

            //about_documenters = {"",""};
            about_artists = { "Daniel Foré <daniel@elementaryos.org>" };
            about_translators = "Launchpad Translators";
            about_license_type = License.GPL_3_0;
        }

        public PantheonTerminalApp () {
            Logger.initialize ("PantheonTerminal");
            Logger.DisplayLevel = LogLevel.DEBUG;

            windows = new GLib.List <PantheonTerminalWindow> ();

            saved_state = new SavedState ();
            settings = new Settings ();
        }

        protected override void activate () {
            if (app_shell_name != null) {
                try {
                    GLib.Process.spawn_command_line_async ("gksu chsh -s " + app_shell_name);
                    return;
                } catch (Error e) {
                    warning (e.message);
                }
            }

            if (command_x != null) {
                new_window_with_programs (command_x);
                return;
            }

            if (command_e != null) {
                new_window_with_commands (command_e);
                return;
            }
            new_window ();
        }

        public void new_window () {
            var window = new PantheonTerminalWindow (this);
            window.show ();
            windows.append (window);
            add_window (window);
        }

        public void new_window_with_coords (int x, int y, bool should_recreate_tabs=true) {
            var window = new PantheonTerminalWindow.with_coords (this, x, y, should_recreate_tabs);
            window.show ();
            windows.append (window);
            add_window (window);
        }

        public void new_window_with_commands (string[] cmd) {
            PantheonTerminalWindow window;
            window = get_last_window ();

            if (window == null) {
                window = new PantheonTerminalWindow (this);
                window.show ();
                windows.append (window);
                add_window (window);
            }

            window.exec_cmd (cmd[0]);

            for (int i = 1; i < cmd.length; i++) {
                window.new_tab_with_cmd (cmd[i]);
            }
        }

        public void new_window_with_programs (string[] programs) {
            PantheonTerminalWindow window;
            window = get_last_window ();

            if (window == null) {
                window = new PantheonTerminalWindow (this, false);
                window.show ();
                windows.append (window);
                add_window (window);
            }

            foreach (string program in programs) {
                string? path = GLib.Environment.find_program_in_path (program);
                if (path != null) {
                    window.run_program_term (path);
                }
            }
        }

        private PantheonTerminalWindow? get_last_window () {
            if (windows.length () > 0) {
                uint length = windows.length ();
                return windows.nth_data (length);
            }
            return null;
        }
        static const OptionEntry[] entries = {
            { "shell", 's', 0, OptionArg.STRING, ref app_shell_name, N_("Set shell at launch"), "" },
            { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
            { "execute" , 'x', 0, OptionArg.STRING_ARRAY, ref command_x, N_("Run a program in terminal"), "" },
            { "run" , 'e', 0, OptionArg.STRING_ARRAY, ref command_e, N_("Execute a command inside the shell"), "" },
            { null }
        };

        public static int main (string[] args) {
            app_cmd_name = "Pantheon Terminal";

            var context = new OptionContext ("File");
            context.add_main_entries (entries, "pantheon-terminal");
            context.add_group (Gtk.get_option_group (true));

            try {
                context.parse (ref args);
            } catch (Error e) {
                stdout.printf ("pantheon-terminal: ERROR: " + e.message + "\n");
                return 0;
            }

            if (print_version) {
                stdout.printf ("Pantheon Terminal %s\n", Constants.VERSION);
                stdout.printf ("Copyright 2011-2012 Terminal Developers.\n");
                return 0;
            }
            var app = new PantheonTerminalApp ();
            return app.run (args);
        }
    }
} // Namespace
