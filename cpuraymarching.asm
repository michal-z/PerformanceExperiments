format PE64 GUI 4.0
entry start

  INFINITE = 0xffffffff
  IDI_APPLICATION = 32512
  IDC_ARROW = 32512
  WS_VISIBLE = 010000000h
  WS_OVERLAPPED = 000000000h
  WS_CAPTION = 000C00000h
  WS_SYSMENU = 000080000h
  WS_VISIBLE = 010000000h
  WS_MINIMIZEBOX = 000020000h
  CW_USEDEFAULT = 80000000h
  PM_REMOVE = 0001h
  WM_QUIT = 0012h
  WM_KEYDOWN = 0100h
  WM_DESTROY = 0002h
  VK_ESCAPE = 01Bh
  SRCCOPY = 0x00CC0020

  k_funcparam5 = 32
  k_funcparam6 = k_funcparam5 + 8
  k_funcparam7 = k_funcparam6 + 8
  k_funcparam8 = k_funcparam7 + 8
  k_funcparam9 = k_funcparam8 + 8
  k_funcparam10 = k_funcparam9 + 8
  k_funcparam11 = k_funcparam10 + 8
  k_funcparam12 = k_funcparam11 + 8

struc POINT {
  .x dd 0
  .y dd 0 }

struc MSG {
  .hwnd dq 0
  .message dd 0,0
  .wParam dq 0
  .lParam dq 0
  .time dd 0
  .pt POINT
  dd 0 }

struc WNDCLASS proc,name {
  .style dd 0,0
  .lpfnWndProc dq proc
  .cbClsExtra dd 0
  .cbWndExtra dd 0
  .hInstance dq 0
  .hIcon dq 0
  .hCursor dq 0
  .hbrBackground dq 0
  .lpszMenuName dq 0
  .lpszClassName dq name }

struc RECT l,t,r,b {
  .left dd l
  .top dd t
  .right dd r
  .bottom dd b }

struc BITMAPINFOHEADER w,h,b,s {
  .biSize dd 40
  .biWidth dd w
  .biHeight dd h
  .biPlanes dw 1
  .biBitCount dw b
  .biCompression dd 0
  .biSizeImage dd s
  .biXPelsPerMeter dd 0
  .biYPelsPerMeter dd 0
  .biClrUsed dd 0
  .biClrImportant dd 0 }

struc SYSTEM_INFO {
  .dwOemId dd 0
  .dwPageSize dd 0
  .lpMinimumApplicationAddress dq 0
  .lpMaximumApplicationAddress dq 0
  .dwActiveProcessorMask dq 0
  .dwNumberOfProcessors dd 0
  .dwProcessorType dd 0
  .dwAllocationGranularity dd 0
  .wProcessorLevel dw 0
  .wProcessorRevision dw 0 }

section '.text' code readable executable
;========================================================================
macro emit [inst] {
forward
        inst }

_0 = 0*32
_1 = 1*32
_2 = 2*32
_3 = 3*32
_4 = 4*32
_5 = 5*32
_6 = 6*32
_7 = 7*32
_8 = 8*32
_9 = 9*32
_10 = 10*32
_11 = 11*32
_12 = 12*32
_13 = 13*32
_14 = 14*32
_15 = 15*32

macro iaca_begin {
        mov         ebx,111
        db          $64,$67,$90 }

macro iaca_end {
        mov         ebx,222
        db          $64,$67,$90 }

macro safe_close handle {
local .end
        mov         rcx,handle
        test        rcx,rcx
        jz          .end
        call        [CloseHandle]
        mov         handle,0
  .end: }

macro falign { align 32 }
macro .calign { align 32 }
;=============================================================================
include 'cpuraymarching_image.inc'
;=============================================================================
align 32
generate_image_thread:
;-----------------------------------------------------------------------------
        and         rsp,-32
        sub         rsp,32
        mov         esi,ecx                                    ; thread id
  .run: mov         rcx,[main_thrd_semaphore]
        mov         edx,INFINITE
        call        [WaitForSingleObject]
        mov         eax,[quit]
        test        eax,eax
        jnz         .return
        call        generate_image
        mov         rcx,[thrd_semaphore+rsi*8]
        mov         edx,1
        xor         r8d,r8d
        call        [ReleaseSemaphore]
        jmp         .run
  .return:
        xor         ecx,ecx
        call        [ExitThread]
;=============================================================================
align 32
supports_avx2:
;-----------------------------------------------------------------------------
        mov         eax,1
        cpuid
        and         ecx,$018001000                             ; check OSXSAVE,AVX,FMA
        cmp         ecx,$018001000
        jne         .not_supported
        mov         eax,7
        xor         ecx,ecx
        cpuid
        and         ebx,$20                                    ; check AVX2
        cmp         ebx,$20
        jne         .not_supported
        xor         ecx,ecx
        xgetbv
        and         eax,$06                                    ; check OS support
        cmp         eax,$06
        jne         .not_supported
        mov         eax,1
        jmp         .return
  .not_supported:
        xor         eax,eax
  .return:
        ret
;=============================================================================
align 32
get_time:
;-----------------------------------------------------------------------------
  .k_stack_size = 7*8
        sub         rsp,.k_stack_size
        mov         rax,[.perf_freq]
        test        rax,rax
        jnz         @f
        lea         rcx,[.perf_freq]
        call        [QueryPerformanceFrequency]
        lea         rcx,[.first_perf_counter]
        call        [QueryPerformanceCounter]
  @@:   lea         rcx,[.perf_counter]
        call        [QueryPerformanceCounter]
        mov         rcx,[.perf_counter]
        sub         rcx,[.first_perf_counter]
        mov         rdx,[.perf_freq]
        vxorps      xmm0,xmm0,xmm0
        vcvtsi2sd   xmm1,xmm0,rcx
        vcvtsi2sd   xmm2,xmm0,rdx
        vdivsd      xmm0,xmm1,xmm2
        add         rsp,.k_stack_size
        ret
;=============================================================================
align 32
update_frame_stats:
;-----------------------------------------------------------------------------
  .k_stack_size = 7*8
        sub         rsp,.k_stack_size
        mov         rax,[.prev_time]
        test        rax,rax
        jnz         @f
        call        get_time
        vmovsd      [.prev_time],xmm0
        vmovsd      [.prev_update_time],xmm0
  @@:   call        get_time                       ; xmm0 = (0,time)
        vmovsd      [time],xmm0
        vsubsd      xmm1,xmm0,[.prev_time]       ; xmm1 = (0,time_delta)
        vmovsd      [.prev_time],xmm0
        vxorps      xmm2,xmm2,xmm2
        vcvtsd2ss   xmm1,xmm2,xmm1            ; xmm1 = (0,0,0,time_delta)
        vmovss      [time_delta],xmm1
        vmovsd      xmm1,[.prev_update_time]     ; xmm1 = (0,prev_update_time)
        vsubsd      xmm2,xmm0,xmm1               ; xmm2 = (0,time-prev_update_time)
        vmovsd      xmm3,[.k_1_0]                ; xmm3 = (0,1.0)
        vcomisd     xmm2,xmm3
        jb          @f
        vmovsd      [.prev_update_time],xmm0
        mov         eax,[.frame]
        vxorpd      xmm1,xmm1,xmm1
        vcvtsi2sd   xmm1,xmm1,eax             ; xmm1 = (0,frame)
        vdivsd      xmm0,xmm1,xmm2               ; xmm0 = (0,frame/(time-prev_update_time))
        vdivsd      xmm1,xmm2,xmm1
        vmulsd      xmm1,xmm1,[.k_1000000_0]
        mov         [.frame],0
        lea         rcx,[win_title]
        lea         rdx,[win_title_fmt]
        vcvtsd2si   r8,xmm0
        vcvtsd2si   r9,xmm1
        call        [wsprintf]
        mov         rcx,[win_handle]
        lea         rdx,[win_title]
        call        [SetWindowText]
  @@:   add         [.frame],1
        add         rsp,.k_stack_size
        ret
;=============================================================================
align 32
init:
;-----------------------------------------------------------------------------
virtual at 0
  rq 12
  .k_stack_size = $+16
end virtual
        push        rsi
        sub         rsp,.k_stack_size
        lea         rcx,[system_info]
        call        [GetSystemInfo]
        mov         eax,[system_info.dwNumberOfProcessors]
        mov         [thrd_count],eax
        call        supports_avx2
        test        eax,eax
        jz          .no_avx2
        ; window class
        xor         ecx,ecx
        call        [GetModuleHandle]
        mov         [win_class.hInstance],rax
        xor         ecx,ecx
        mov         edx,IDC_ARROW
        call        [LoadCursor]
        mov         [win_class.hCursor],rax
        mov         rcx,win_class
        call        [RegisterClass]
        test        eax,eax
        jz          .error
        ; window
        mov         rcx,win_rect
        mov         edx,k_win_style
        xor         r8d,r8d
        call        [AdjustWindowRect]
        mov         r10d,[win_rect.right]
        mov         r11d,[win_rect.bottom]
        sub         r10d,[win_rect.left]
        sub         r11d,[win_rect.top]
        xor         ecx,ecx
        mov         rdx,win_title
        mov         r8,rdx
        mov         r9d,WS_VISIBLE+k_win_style
        mov         eax,CW_USEDEFAULT
        mov         [k_funcparam5+rsp],eax
        mov         [k_funcparam6+rsp],eax
        mov         [k_funcparam7+rsp],r10d
        mov         [k_funcparam8+rsp],r11d
        mov         [k_funcparam9+rsp],ecx
        mov         [k_funcparam10+rsp],ecx
        mov         rax,[win_class.hInstance]
        mov         [k_funcparam11+rsp],rax
        mov         [k_funcparam12+rsp],ecx
        call        [CreateWindowEx]
        mov         [win_handle],rax
        test        rax,rax
        jz          .error
        ; bitmap
        mov         rcx,[win_handle]
        call        [GetDC]
        mov         [win_hdc],rax
        test        rax,rax
        jz          .error
        mov         rcx,[win_hdc]
        lea         rdx,[bmp_info]
        xor         r8d,r8d
        lea         r9,[displayptr]
        mov         qword[k_funcparam5+rsp],0
        mov         qword[k_funcparam6+rsp],0
        call        [CreateDIBSection]
        mov         [bmp_handle],rax
        test        rax,rax
        jz          .error
        mov         rcx,[win_hdc]
        call        [CreateCompatibleDC]
        mov         [bmp_hdc],rax
        test        rax,rax
        jz          .error
        mov         rcx,[bmp_hdc]
        mov         rdx,[bmp_handle]
        call        [SelectObject]
        test        eax,eax
        jz          .error
        ; semaphores
        xor         ecx,ecx
        xor         edx,edx
        mov         r8d,[thrd_count]
        xor         r9d,r9d
        call        [CreateSemaphore]
        mov         [main_thrd_semaphore],rax
        test        rax,rax
        jz          .error
        xor         esi,esi
  @@:   xor         ecx,ecx
        xor         edx,edx
        mov         r8d,1
        xor         r9d,r9d
        call        [CreateSemaphore]
        mov         [thrd_semaphore+rsi*8],rax
        test        rax,rax
        jz          .error
        add         esi,1
        cmp         esi,[thrd_count]
        jb          @b
        ; threads
        xor         esi,esi
  @@:   xor         ecx,ecx
        xor         edx,edx
        mov         r8,generate_image_thread
        mov         r9d,esi
        mov         qword[k_funcparam5+rsp],0
        mov         qword[k_funcparam6+rsp],0
        call        [CreateThread]
        mov         [thrd_handle+rsi*8],rax
        test        rax,rax
        jz          .error
        add         esi,1
        cmp         esi,[thrd_count]
        jb          @b
        mov         eax,1
        add         rsp,.k_stack_size
        pop         rsi
        ret
  .no_avx2:
        xor         ecx,ecx
        lea         rdx,[no_avx2_message]
        lea         r8,[no_avx2_caption]
        xor         r9d,r9d
        call        [MessageBox]
  .error:
        xor         eax,eax
        add         rsp,.k_stack_size
        pop         rsi
        ret
;=============================================================================
align 32
deinit:
;-----------------------------------------------------------------------------
  .k_stack_size = 5*8
        push        rsi rdi
        sub         rsp,.k_stack_size
        mov         [quit],1
        mov         rcx,[main_thrd_semaphore]
        test        rcx,rcx
        jz          @f
        mov         edx,[thrd_count]
        xor         r8d,r8d
        call        [ReleaseSemaphore]
  @@:   xor         esi,esi
  .for_each_thrd:
        mov         rdi,[thrd_handle+rsi*8]
        test        rdi,rdi
        jz          @f
        mov         rcx,rdi
        mov         edx,INFINITE
        call        [WaitForSingleObject]
        mov         rcx,rdi
        call        [CloseHandle]
  @@:   add         esi,1
        cmp         esi,[thrd_count]
        jb          .for_each_thrd
        xor         esi,esi
  .for_each_sem:
        safe_close  [thrd_semaphore+rsi*8]
        add         esi,1
        cmp         esi,[thrd_count]
        jb          .for_each_sem
        safe_close  [main_thrd_semaphore]
        mov         rcx,[bmp_hdc]
        test        rcx,rcx
        jz          @f
        call        [DeleteDC]
  @@:   mov         rcx,[bmp_handle]
        test        rcx,rcx
        jz          @f
        call        [DeleteObject]
  @@:   mov         rcx,[win_hdc]
        test        rcx,rcx
        jz          @f
        call        [ReleaseDC]
  @@:   add         rsp,.k_stack_size
        pop         rdi rsi
        ret
;=============================================================================
align 32
update:
;-----------------------------------------------------------------------------
virtual at 0
  rq 9
  .k_stack_size = $+16
end virtual
        sub         rsp,.k_stack_size
        call        update_frame_stats
        call        update_state
        mov         [tileidx],0
        mov         rcx,[main_thrd_semaphore]
        mov         edx,[thrd_count]
        xor         r8d,r8d
        call        [ReleaseSemaphore]
        mov         ecx,[thrd_count]
        lea         rdx,[thrd_semaphore]
        mov         r8d,1
        mov         r9d,INFINITE
        call        [WaitForMultipleObjects]
        mov         rcx,[win_hdc]
        xor         edx,edx
        xor         r8d,r8d
        mov         r9d,k_win_width
        mov         dword[k_funcparam5+rsp],k_win_height
        mov         rax,[bmp_hdc]
        mov         [k_funcparam6+rsp],rax
        mov         qword[k_funcparam7+rsp],0
        mov         qword[k_funcparam8+rsp],0
        mov         dword[k_funcparam9+rsp],SRCCOPY
        call        [BitBlt]
        add         rsp,.k_stack_size
        ret
;=============================================================================
align 32
start:
;-----------------------------------------------------------------------------
virtual at 0
  rq 5
  .k_stack_size = $+16
end virtual
        sub         rsp,.k_stack_size
        call        init
        test        eax,eax
        jz          .quit
  .main_loop:
        lea         rcx,[win_msg]
        xor         edx,edx
        xor         r8d,r8d
        xor         r9d,r9d
        mov         dword[k_funcparam5+rsp],PM_REMOVE
        call        [PeekMessage]
        test        eax,eax
        jz          .update
        lea         rcx,[win_msg]
        call        [DispatchMessage]
        cmp         [win_msg.message],WM_QUIT
        je          .quit
        jmp         .main_loop
  .update:
        call        update
        jmp         .main_loop
  .quit:
        call        deinit
        xor         ecx,ecx
        call        [ExitProcess]
;=============================================================================
align 32
winproc:
;-----------------------------------------------------------------------------
        sub         rsp,40
        cmp         edx,WM_KEYDOWN
        je          .keydown
        cmp         edx,WM_DESTROY
        je          .destroy
        call        [DefWindowProc]
        jmp         .return
  .keydown:
        cmp         r8d,VK_ESCAPE
        jne         .return
        xor         ecx,ecx
        call        [PostQuitMessage]
        xor         eax,eax
        jmp         .return
  .destroy:
        xor         ecx,ecx
        call        [PostQuitMessage]
        xor         eax,eax
  .return:
        add         rsp,40
        ret
;========================================================================
section '.data' data readable writeable

  k_win_width = 1280
  k_win_height = 720
  k_win_style = WS_OVERLAPPED+WS_SYSMENU+WS_CAPTION+WS_MINIMIZEBOX

  k_tile_width = 80
  k_tile_height = 80
  k_tile_x_count = k_win_width / k_tile_width
  k_tile_y_count = k_win_height / k_tile_height
  k_tile_count = k_tile_x_count * k_tile_y_count

  k_thrd_max_count = 16

align 8
  bmp_handle dq 0
  bmp_hdc dq 0
  win_handle dq 0
  win_hdc dq 0
  win_title db 'CPU Raymarching', 64 dup 0
  win_title_fmt db '[%d fps  %d us] CPU Raymarching',0
  win_msg MSG
  win_class WNDCLASS winproc,win_title
  win_rect RECT 0,0,k_win_width,k_win_height

  no_avx2_caption db 'Not supported CPU',0
  no_avx2_message db 'Your CPU does not support AVX2, program will not run.',0

align 8
  bmp_info BITMAPINFOHEADER k_win_width,k_win_height,32,k_win_width*k_win_height
  dq 0,0,0,0

align 8
  time dq 0
  time_delta dd 0
  quit dd 0

  get_time.perf_counter dq 0
  get_time.perf_freq dq 0
  get_time.first_perf_counter dq 0

  update_frame_stats.prev_time dq 0
  update_frame_stats.prev_update_time dq 0
  update_frame_stats.frame dd 0,0
  update_frame_stats.k_1000000_0 dq 1000000.0
  update_frame_stats.k_1_0 dq 1.0

  displayptr dq 0
  tileidx dd 0,0

align 8
  main_thrd_semaphore dq 0
  thrd_handle dq k_thrd_max_count dup 0
  thrd_semaphore dq k_thrd_max_count dup 0
  thrd_count dd 0

  system_info SYSTEM_INFO

align 4
  eye_position dd 0.0,4.0,400.0
  eye_focus dd 0.0,0.0,0.0
  k_background_color dd 0.0,0.0,0.0

align 32
  eye_xaxis: dd 8 dup 1.0,8 dup 0.0,8 dup 0.0
  eye_yaxis: dd 8 dup 0.0,8 dup 1.0,8 dup 0.0
  eye_zaxis: dd 8 dup 0.0,8 dup 0.0,8 dup 1.0

align 32
  generate_image.k_x_offset: dd 0.5,1.5,2.5,3.5,0.5,1.5,2.5,3.5
  generate_image.k_y_offset: dd 0.5,0.5,0.5,0.5,1.5,1.5,1.5,1.5
  generate_image.k_win_width_rcp: dd 8 dup 0.0015625      ; 2.0f / k_win_width, k_win_width = 1280
  generate_image.k_win_height_rcp: dd 8 dup 0.0015625     ; 2.0f / k_win_width, k_win_width = 1280
  generate_image.k_rd_z: dd 8 dup -1.732

align 32
  k_1: dd 8 dup 1
  k_2: dd 8 dup 2
  k_1_0: dd 8 dup 1.0
  k_0_5: dd 8 dup 0.5
  k_0_1: dd 8 dup 0.1
  k_camera_radius: dd 8 dup 16.0
  k_sphere_radius: dd 8 dup -4.0
  k_255_0: dd 8 dup 255.0
  k_0_02: dd 8 dup 0.02
  k_hit_distance: dd 8 dup 0.0002
  k_view_distance: dd 8 dup 40.0
  k_normal_eps: dd 8 dup 0.02
  k_shadow_hardness: dd 8 dup 16.0

align 32
  light0_position: dd 8 dup 10.0, 8 dup 10.0, 8 dup 10.0
  light0_power: dd 8 dup 0.9
  light1_position: dd 8 dup 5.0, 8 dup 20.0, 8 dup -15.0
  light1_power: dd 8 dup 0.6
  ambient: dd 8 dup 0.1

align 32
  object:
  .id:      dd 8 dup 0,8 dup 8,8 dup 16,8 dup 24
  .param_x: dd 0.0, 0.0, 3.0, 0.0
  .param_y: dd 0.0, 1.0, 0.0, 1.0
  .param_z: dd 0.0, 3.0, 0.0, 0.0
  .param_w: dd 2.0, 0.7, 1.0, 2.0
  .red:     dd 8 dup 1.0,8 dup 0.0,8 dup 0.0,8 dup 0.5
  .green:   dd 8 dup 0.0,8 dup 1.0,8 dup 0.0,8 dup 0.3
  .blue:    dd 8 dup 0.0,8 dup 0.0,8 dup 1.0,8 dup 0.2

align 32
  sincos.k_inv_sign_mask: dd 8 dup not 0x80000000
  sincos.k_sign_mask: dd 8 dup 0x80000000
  sincos.k_2_div_pi: dd 8 dup 0.636619772
  sincos.k_p0: dd 8 dup 0.15707963267948963959e1
  sincos.k_p1: dd 8 dup -0.64596409750621907082e0
  sincos.k_p2: dd 8 dup 0.7969262624561800806e-1
  sincos.k_p3: dd 8 dup -0.468175413106023168e-2
;========================================================================
section '.idata' import data readable writeable

  dd 0,0,0,rva _kernel32,rva _kernel32_table
  dd 0,0,0,rva _user32,rva _user32_table
  dd 0,0,0,rva _gdi32,rva _gdi32_table
  dd 0,0,0,0,0

  _kernel32_table:
  GetModuleHandle dq rva _GetModuleHandle
  ExitProcess dq rva _ExitProcess
  WaitForSingleObject dq rva _WaitForSingleObject
  ReleaseSemaphore dq rva _ReleaseSemaphore
  ExitThread dq rva _ExitThread
  QueryPerformanceFrequency dq rva _QueryPerformanceFrequency
  QueryPerformanceCounter dq rva _QueryPerformanceCounter
  CreateSemaphore dq rva _CreateSemaphore
  CreateThread dq rva _CreateThread
  CloseHandle dq rva _CloseHandle
  WaitForMultipleObjects dq rva _WaitForMultipleObjects
  GetSystemInfo dq rva _GetSystemInfo
  dq 0

  _user32_table:
  wsprintf dq rva _wsprintf
  RegisterClass dq rva _RegisterClass
  CreateWindowEx dq rva _CreateWindowEx
  DefWindowProc dq rva _DefWindowProc
  PeekMessage dq rva _PeekMessage
  DispatchMessage dq rva _DispatchMessage
  LoadCursor dq rva _LoadCursor
  LoadIcon dq rva _LoadIcon
  SetWindowText dq rva _SetWindowText
  SetRect dq rva _SetRect
  AdjustWindowRect dq rva _AdjustWindowRect
  GetDC dq rva _GetDC
  ReleaseDC dq rva _ReleaseDC
  PostQuitMessage dq rva _PostQuitMessage
  MessageBox dq rva _MessageBox
  dq 0

  _gdi32_table:
  CreateDIBSection dq rva _CreateDIBSection
  CreateCompatibleDC dq rva _CreateCompatibleDC
  SelectObject dq rva _SelectObject
  BitBlt dq rva _BitBlt
  DeleteDC dq rva _DeleteDC
  DeleteObject dq rva _DeleteObject
  dq 0

  _kernel32 db 'kernel32.dll',0
  _user32 db 'user32.dll',0
  _gdi32 db 'gdi32.dll',0

emit <_GetModuleHandle dw 0>,<db 'GetModuleHandleA',0>
emit <_ExitProcess dw 0>,<db 'ExitProcess',0>
emit <_WaitForSingleObject dw 0>,<db 'WaitForSingleObject',0>
emit <_ReleaseSemaphore dw 0>,<db 'ReleaseSemaphore',0>
emit <_ExitThread dw 0>,<db 'ExitThread',0>
emit <_QueryPerformanceFrequency dw 0>,<db 'QueryPerformanceFrequency',0>
emit <_QueryPerformanceCounter dw 0>,<db 'QueryPerformanceCounter',0>
emit <_CreateSemaphore dw 0>,<db 'CreateSemaphoreA',0>
emit <_CreateThread dw 0>,<db 'CreateThread',0>
emit <_CloseHandle dw 0>,<db 'CloseHandle',0>
emit <_WaitForMultipleObjects dw 0>,<db 'WaitForMultipleObjects',0>
emit <_GetSystemInfo dw 0>,<db 'GetSystemInfo',0>

emit <_wsprintf dw 0>,<db 'wsprintfA',0>
emit <_RegisterClass dw 0>,<db 'RegisterClassA',0>
emit <_CreateWindowEx dw 0>,<db 'CreateWindowExA',0>
emit <_DefWindowProc dw 0>,<db 'DefWindowProcA',0>
emit <_PeekMessage dw 0>,<db 'PeekMessageA',0>
emit <_DispatchMessage dw 0>,<db 'DispatchMessageA',0>
emit <_LoadCursor dw 0>,<db 'LoadCursorA',0>
emit <_LoadIcon dw 0>,<db 'LoadIconA',0>
emit <_SetWindowText dw 0>,<db 'SetWindowTextA',0>
emit <_SetRect dw 0>,<db 'SetRect',0>
emit <_AdjustWindowRect dw 0>,<db 'AdjustWindowRect',0>
emit <_GetDC dw 0>,<db 'GetDC',0>
emit <_ReleaseDC dw 0>,<db 'ReleaseDC',0>
emit <_PostQuitMessage dw 0>,<db 'PostQuitMessage',0>
emit <_MessageBox dw 0>,<db 'MessageBoxA',0>

emit <_CreateDIBSection dw 0>,<db 'CreateDIBSection',0>
emit <_CreateCompatibleDC dw 0>,<db 'CreateCompatibleDC',0>
emit <_SelectObject dw 0>,<db 'SelectObject',0>
emit <_BitBlt dw 0>,<db 'BitBlt',0>
emit <_DeleteDC dw 0>,<db 'DeleteDC',0>
emit <_DeleteObject dw 0>,<db 'DeleteObject',0>
;========================================================================