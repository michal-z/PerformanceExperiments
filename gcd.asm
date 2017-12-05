; Greatest common divisor (gcd).
; Algorithm 1.1E (Euclids's algorithm) implemented in x86_64 assembly language.
; To generate executable file open it in fasmw.exe editor and press F9.

format PE64 console
entry start

macro falign { align 16 }
macro icall addr* { call [addr] }
macro locals {
    virtual at rsp
    .shadow_ dq ?,?,?,?
    .fparam5 dq ?
    .fparam6 dq ?
    .fparam7 dq ?
    .fparam8 dq ?
}
macro endl {
    .localsize = $-$$
    end virtual
}

section '.text' code readable executable

falign
gcd:    CMP rcx, rdx            ; switch m <-> n so that m = rdx, n = rcx (for easier division)
        JBE .compute_loop       ; also make sure that n < m
        XCHG rcx, rdx
.compute_loop:
        MOV rax, rdx            ; mov m (rdx) to rax for division
        XOR edx, edx            ; zero out rdx for division
        DIV rcx                 ; divide m / n (rdx:rax / rcx)
        INC [iter_count]
        TEST rdx, rdx           ; remainder r = rdx, if (r == 0) n (rcx) is the answer
        JZ .done
        XCHG rdx, rcx           ; set m = n, n = r
        JMP .compute_loop       ; repeat
.done:  MOV rax, rcx
        RET

falign
print_answer:
        SUB rsp, 5*8
        MOV [rsp], rcx          ; [rsp] = m
        MOV [rsp+8], rdx        ; [rsp+8] = n
        MOV [rsp+16], r8        ; [rsp+16] = d
        LEA rcx, [s.answer]
        MOV rdx, [rsp]
        MOV r8, [rsp+8]
        MOV r9, [rsp+16]
        MOV eax, [iter_count]
        MOV dword [rsp+32], eax
        CALL [printf]
        ADD rsp, 5*8
        RET

falign
main:
        sub     rsp,32
        push    rsi
        xor     esi,esi
    .loop:
        mov     rcx,[inputs+rsi*8]
        test    rcx,rcx
        jz      .exit
        mov     rdx,[inputs+rsi*8+8]
        mov     [iter_count],0
        call    gcd
        mov     rcx,[inputs+rsi*8]
        mov     rdx,[inputs+rsi*8+8]
        mov     r8,rax
        call    print_answer
        add     esi,2
        jmp     .loop
    .exit:
        pop     rsi
        add     rsp,32
        ret
falign
start:
        sub     rsp,40
        lea     rcx,[_kernel32]
        icall   LoadLibrary
        mov     [kernel32],rax                  ; kernel32.dll
        lea     rcx,[_msvcrt]
        icall   LoadLibrary
        mov     [msvcrt],rax                    ; msvcrt.dll
        mov     rcx,[kernel32]
        lea     rdx,[_ExitProcess]
        icall   GetProcAddress
        mov     [ExitProcess],rax               ; ExitProcess
        mov     rcx,[msvcrt]
        lea     rdx,[_getch]
        icall   GetProcAddress
        mov     [getch],rax                     ; getch
        mov     rcx,[msvcrt]
        lea     rdx,[_printf]
        icall   GetProcAddress
        mov     [printf],rax                    ; printf
        call    main
        lea     rcx,[_exit]
        icall   printf
        icall   getch
        xor     ecx,ecx
        icall   ExitProcess

section '.data' data readable writeable

inputs          dq 270,192, 177,137688, 1000,10, 37123781,27821, 19999999999999,19999912341, 0
iter_count      dd 0

align 8
kernel32        dq 0
msvcrt          dq 0
getch           dq 0
ExitProcess     dq 0
printf          dq 0

_kernel32       db 'kernel32.dll',0
_msvcrt         db 'msvcrt.dll',0
_ExitProcess    db 'ExitProcess',0
_getch          db '_getch',0
_printf         db 'printf',0
_exit           db 'Hit any key to exit this program...',13,10,0
s.answer         db 'gcd(%llu, %llu) = %llu (Number of iterations: %u).',13,10,0

section '.idata' import data readable writeable

                dd 0,0,0
                dd rva _kernel32
                dd rva LoadLibrary
                dd 0,0,0,0,0
LoadLibrary     dq rva _LoadLibrary
GetProcAddress  dq rva _GetProcAddress
                dq 0
_LoadLibrary    dw 0
                db 'LoadLibraryA',0
_GetProcAddress dw 0
                db 'GetProcAddress',0
