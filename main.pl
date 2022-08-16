:- use_module('ref/amd64.pl').

instructions(B) :-
    findall(
	(N, Sf, A, S, Src, Dest, Flags),
	instruction(N, Sf, A, S, Src, Dest, Flags), B).

exceptions(Op, B) :-
    findall((Exception, Cause), excep(Op, Exception, Cause), B).

string_type((mem, reg, imm), S) :-
    S = "a memory address, a register, or an immediate value".

string_type((mem, reg), S) :-
    S = "a memory address or a register".

string_type((reg), S) :-
    S = "a register".

n_srcs(Stream, 1) :- write(Stream, "src1").
n_srcs(Stream, N) :-
    N =\= 1,

    Before is N - 1, n_srcs(Stream, Before),
    format(Stream, ', src~D', N).

write_n_types(Stream, TypesList) :-
    % Reversing the list makes the recursion in _inner a bit more
    % straightforward.
    reverse(TypesList, TypesListR),
    write_n_types_inner(Stream, TypesListR).

write_n_types_inner(Stream, TypesList) :-
    [H | T] = TypesList,
    length(T, N),

    ( ( N =\= 0
      , write_n_types_inner(Stream, T))
    ; ( true )),

    Index is N + 1,

    string_type(H, StrTypes),
    
    write(Stream, "* src"),
    write(Stream, Index),
    write(Stream, " may be "),
    write(Stream, StrTypes),
    write(Stream, ".\n").

write_gnu_with_suffix(Stream, Name, Srcs, Dsts, Sf) :-
    downcase_atom(Name, MnemonicRoot),
    atom_concat(MnemonicRoot, Sf, Mnemonic),

    write(Stream, Mnemonic),
    write(Stream, " "),

    length(Srcs, N), length(Dsts, M),

    ( ( N =:= 0 )
    ; ( N =:= 1
      , write(Stream, "src"))
    ; ( n_srcs(Stream, N) )),

    ( ( N > 0, M > 0
      , write(Stream, ", "))
    ; ( true )),
    
    ( ( M =:= 0 )
    ; ( M =:= 1
      , write(Stream, "dst"))
    ; ( write(Stream, "Support for multiple destinations TODO.") )),

    write(Stream, "\n").

write_int_usage(Stream, Name, Sfs, Srcs, Dsts) :-
    write(Stream, "Intel-syntax usage segment TODO.").

write_gnu_usage(Stream, Name, Sfs, Srcs, Dsts) :-
    write(Stream, "```Usage overview.\n"),
    maplist(write_gnu_with_suffix(Stream, Name, Srcs, Dsts), Sfs),
    write(Stream, "```\n\n"),

    length(Srcs, N),
    length(Dsts, M),

    ( ( N =:= 0 ) % nop
    ; ( N =:= 1
      , nth0(0, Srcs, Src)
      , string_type(Src, Types)
      , write(Stream, "* src may be ")
      , write(Stream, Types)
      , write(Stream, ".\n"))
    ; ( write_n_types(Stream, Srcs)) ),

    ( ( M =:= 0 ) % nop
    ; ( M =:= 1
      , nth0(0, Dsts, Dst)
      , string_type(Dst, DTypes)
      , write(Stream, "* dst may be ")
      , write(Stream, DTypes)
      , write(Stream, "."))
    ; ( true )). % TODO

write_ins(Stream, (Name, Sf, Action, Desc, Src, Dst, Flags), UsagePredicate) :-
    write(Stream, "### "),
    write(Stream, Name),
    write(Stream, " ["),
    write(Stream, Action),
    write(Stream, " ]\n"),
    write(Stream, Desc),
    write(Stream, "\n\n"),

    ( ( length(Src, 0), length(Dst, 0),
        write(Stream, "This instruction requires no explicit operands."))
    ; ( call(UsagePredicate, Stream, Name, Sf, Src, Dst) ) ),
    write(Stream, "\n\n"),

    exceptions(Name, Exceptions),

    ( ( length(Exceptions, 0)
      , write(Stream, "This instruction requires no explicit operands.") )
    ; ( write(Stream, "This may cause the following exceptions:\n")
      , maplist(write_excep(Stream), Exceptions) ) ),
    write(Stream, "\n"),

    ( ( not(length(Flags, 0))
      , write(Stream, "The following flags may be updated: ")
      , write(Stream, Flags) )
    ; true),

    write(Stream, "\n").

write_gnu_ins(Stream, Ins) :-
    write_ins(Stream, Ins, write_gnu_usage).

write_int_ins(Stream, Ins) :-
    write_ins(Stream, Ins, write_int_usage).

write_excep(Stream, (Excep, Cause)) :-
    write(Stream, "* "),
    write(Stream, Excep),
    write(Stream, ", when "),
    write(Stream, Cause),
    write(Stream, ".\n").

ins_matching(Stream, NonNormalQuery) :-
    string_upper(NonNormalQuery, Query),
    instructions(B),
    include(ins_matches(Query), B, C),

    ( ( length(C, 0)
      , write(Stream, "No results found.\n"))
    ; ( maplist(write_gnu_ins(Stream), C)
      ) ).

ins_matches(Query, (Mnemonic, _, Name, _, _, _)) :-
    ( sub_atom(Mnemonic, _, _, _, Query)
    ; sub_atom(Name,     _, _, _, Query)).

gemini :- server(1965).

server(Port) :-
    tcp_socket(Socket),
    tcp_bind(Socket, Port),
    tcp_listen(Socket, 5),
    setup_call_cleanup(
	tcp_open_socket(Socket, SFd, _),
	handle(SFd),
	close(SFd)).

handle(SFd) :-
    tcp_accept(SFd, Socket, _),

    cert_file(Cf),
    key_file(Kf),
    ssl_context(server, Ctx, [
		    close_notify(true),
		    close_parent(true),
		    certificate_file(Cf),
		    key_file(Kf)
		]),

    % todo: async or threading - after some (TODO) memoization, we'll
    % probably spend most of our time blocked in IO, so running
    % multiple IO ops at once is probably a good idea.
    tcp_open_socket(Socket, StreamPair),
    (process_rq(StreamPair, Ctx) ->
            write(user_error, "Client served successfully.\n");
	    write(user_error, "Client failed.\n")),

    handle(SFd).

process_rq(StreamPair, Ctx) :-
    catch(
	connect_with_tls(Ctx, StreamPair, TlsPair),
	_, false),

    respond(TlsPair),
    close(TlsPair).

connect_with_tls(Ctx, PlainPair, TlsPair) :-
    stream_pair(PlainPair, PlainRead, PlainWrite),
    ssl_negotiate(Ctx, PlainRead, PlainWrite, TlsRead, TlsWrite),
    stream_pair(TlsPair, TlsRead, TlsWrite).

cert_file(File) :- getenv("GEMASM_TLS_CERT", File).
key_file(File)  :- getenv("GEMASM_TLS_KEY",  File).

respond(TlsPair) :-
    read_line_to_string(TlsPair, Request),
    write(Request), nl,
    
    ( route(TlsPair, Request)
    ; write(TlsPair, "59\r\n")).

route(TlsPair, Url) :-
    good_request(Url, Path),

    ( index(TlsPair, Path)
    ; index_gnu(TlsPair, Path)
    ; index_int(TlsPair, Path)
    ; search_gnu(TlsPair, Path)
    ; search_results_gnu(TlsPair, Path)
    ; not_found(TlsPair)).

index_gnu(TlsPair, Path) :-
    Path == "gnu/",

    write(TlsPair, "20 text/gemini\r\n"),
    write(TlsPair, "# [GNU] x86 Assembly Reference\n"),
    write(TlsPair, "=> search Search\n\n"),

    write(TlsPair, "## All Instructions\n"),

    instructions(Ins),
    maplist(write_gnu_ins(TlsPair), Ins).

index_int(TlsPair, Path) :-
    Path == "int/",
    
    write(TlsPair, "20 text/gemini\r\n"),
    write(TlsPair, "# [INTEL] x86 Assembly Reference\n"),
    write(TlsPair, "=> search Search\n\n"),

    write(TlsPair, "## All Instructions\n"),
    
    instructions(Ins),
    maplist(write_int_ins(TlsPair, Ins)).

search_gnu(TlsPair, Path) :-
    Path == "gnu/search",

    write(TlsPair, "10 Query term\r\n").

search_results_gnu(TlsPair, Path) :-
    sub_string(Path, 0, 11, _, "gnu/search?"), !,
    sub_string(Path, 11, _, 0, EncodedQuery),
    
    uri_encoded(path, Query, EncodedQuery),

    write(TlsPair, "20 text/gemini\r\n"),
    write(TlsPair, "=> ./ Instruction Index\n\n"),

    ins_matching(TlsPair, Query).
    

index(TlsPair, Path) :-
    string_length(Path, 0),

    write(TlsPair, "20 text/gemini\r\n"),
    write(TlsPair, "# x86 Assembly Reference\n\n"),

    write(TlsPair, "=> /gnu/ GNU-Format Instruction Index\n"),
    write(TlsPair, "=> /int/ Intel-Format Instruction Index\n\n"),

    write(TlsPair, "=> /gnu/search Search (GNU mnemonics)\n"),
    write(TlsPair, "=> /int/search Search (Intel mnemonics)\n\n"),

    write(TlsPair, "This information is all *probably* right, but don't take \c
    it as authoritative. This is a quick reference, not a specification.\n\n"),

    write(TlsPair, "Copyright 2022. This Gemini server is Free Software, released under the terms of the GNU Affero General Public License. "),
    write(TlsPair, "Note that the above copyright and license notice do not apply to redistributed and adapted data regarding the specifics of the AMD64 ISA. Consult the README of this distribution for more information.\n\n"),
    write(TlsPair, "=> https://github.com/lincolnauster/gemasmref/ Source Code (web)\n").

not_found(TlsPair) :-
    write(TlsPair, "51\r\n").

/* Verify that the request is to a valid Gemspace URI, and set Path to
 * the server-root-relative location. */
good_request(Url, Path) :-
    good_scheme(Url, WithoutScheme),
    good_path(WithoutScheme, Path).

good_scheme(Url, R) :-
    sub_string(Url, 0, 9, _, "gemini://"), !,
    sub_string(Url, 9, _, 0, R).

good_path(Url, R) :-
    sub_string(Url, DomainLen, 1, _, "/"), !,
    Padding is DomainLen + 1,
    sub_string(Url, Padding, _, 0, R).
     
