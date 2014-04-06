% Bower - a frontend for the Notmuch email system
% Copyright (C) 2011 Peter Wang

:- module prog_config.
:- interface.

:- import_module io.
:- import_module maybe.

:- type prog_config.

:- pred load_prog_config(maybe_error(prog_config)::out, io::di, io::uo) is det.

:- pred check_sendmail_command(prog_config::in, maybe_error::out) is det.

:- pred get_notmuch_prefix(prog_config::in, string::out) is det.

:- pred get_notmuch_deliver_prefix(prog_config::in, string::out) is det.

:- pred get_editor_command(prog_config::in, string::out) is det.

:- type sendmail_option
    --->    sendmail_no_read_recipients
    ;       sendmail_read_recipients. % '-t' option

:- pred get_sendmail_command(prog_config::in, sendmail_option::in,
    string::out) is det.

:- pred get_maybe_post_sendmail_command(prog_config::in, maybe(string)::out)
    is det.

:- pred get_maybe_html_dump_command(prog_config::in, maybe(string)::out)
    is det.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module map.
:- import_module string.

:- import_module config.
:- import_module xdg.

:- type prog_config
    --->    prog_config(
                notmuch         :: string,
                notmuch_deliver :: string,
                editor          :: string,
                sendmail        :: string,
                post_sendmail   :: maybe(string),
                html_dump       :: maybe(string)
            ).

%-----------------------------------------------------------------------------%

load_prog_config(Res, !IO) :-
    search_config_file(config_filename, MaybeConfigFile, !IO),
    (
        MaybeConfigFile = yes(ConfigFile),
        load_config_file(ConfigFile, LoadRes, !IO),
        (
            LoadRes = ok(Config),
            make_prog_config(Config, ProgConfig, !IO),
            Res = ok(ProgConfig)
        ;
            LoadRes = error(Error),
            Res = error(io.error_message(Error))
        )
    ;
        MaybeConfigFile = no,
        make_prog_config(init_config, ProgConfig, !IO),
        Res = ok(ProgConfig)
    ).

:- pred make_prog_config(config::in, prog_config::out, io::di, io::uo) is det.

make_prog_config(Config, ProgConfig, !IO) :-
    ( search_config(Config, "command", "notmuch", Notmuch0) ->
        Notmuch = Notmuch0
    ;
        Notmuch = default_notmuch_command
    ),

    ( search_config(Config, "command", "notmuch_deliver", NotmuchDeliver0) ->
        NotmuchDeliver = NotmuchDeliver0
    ;
        NotmuchDeliver = default_notmuch_deliver_command
    ),

    ( search_config(Config, "command", "editor", Editor0) ->
        Editor = Editor0
    ;
        io.get_environment_var("EDITOR", MaybeEditor, !IO),
        (
            MaybeEditor = yes(Editor)
        ;
            MaybeEditor = no,
            Editor = default_editor_command
        )
    ),

    ( search_config(Config, "command", "sendmail", Sendmail0) ->
        Sendmail = Sendmail0
    ;
        Sendmail = default_sendmail_command
    ),

    ( search_config(Config, "command", "post_sendmail", PostSendmail) ->
        MaybePostSendmail = yes(PostSendmail)
    ;
        MaybePostSendmail = no
    ),

    ( search_config(Config, "command", "html_dump", HtmlDump) ->
        ( HtmlDump = "" ->
            MaybeHtmlDump = no
        ;
            MaybeHtmlDump = yes(HtmlDump)
        )
    ;
        MaybeHtmlDump = yes(default_html_dump_command)
    ),

    ProgConfig ^ notmuch = Notmuch,
    ProgConfig ^ notmuch_deliver = NotmuchDeliver,
    ProgConfig ^ editor = Editor,
    ProgConfig ^ sendmail = Sendmail,
    ProgConfig ^ post_sendmail = MaybePostSendmail,
    ProgConfig ^ html_dump = MaybeHtmlDump.

%-----------------------------------------------------------------------------%

check_sendmail_command(Config, Res) :-
    get_sendmail_command(Config, sendmail_no_read_recipients, Command),
    (
        ( string.suffix(Command, " -t")
        ; string.sub_string_search(Command, " -t ", _)
        )
    ->
        Res = error("Please remove -t option from command.sendmail:  " ++ Command)
    ;
        Res = ok
    ).

%-----------------------------------------------------------------------------%

get_notmuch_prefix(Config, Notmuch) :-
    Notmuch = Config ^ notmuch ++ " ".

get_notmuch_deliver_prefix(Config, NotmuchDeliver) :-
    NotmuchDeliver = Config ^ notmuch_deliver ++ " ".

get_editor_command(Config, Command) :-
    Command = Config ^ editor.

get_sendmail_command(Config, Option, Command) :-
    Command0 = Config ^ sendmail,
    (
        Option = sendmail_no_read_recipients,
        Command = Command0
    ;
        Option = sendmail_read_recipients,
        Command = Command0 ++ " -t"
    ).

get_maybe_post_sendmail_command(Config, MaybeCommand) :-
    MaybeCommand = Config ^ post_sendmail.

get_maybe_html_dump_command(Config, MaybeCommand) :-
    MaybeCommand = Config ^ html_dump.

%-----------------------------------------------------------------------------%

:- func config_filename = string.

config_filename = "bower/bower.conf".

:- func default_notmuch_command = string.

default_notmuch_command = "notmuch".

:- func default_notmuch_deliver_command = string.

default_notmuch_deliver_command = "notmuch-deliver".

:- func default_editor_command = string.

default_editor_command = "vi".

:- func default_sendmail_command = string.

default_sendmail_command = "/usr/bin/sendmail -oi -oem".

:- func default_html_dump_command = string.

default_html_dump_command = "lynx -dump -force-html -stdin -display-charset=utf-8".

%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sts=4 sw=4 et
