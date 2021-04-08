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
  inst
}

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
  MOV ebx,111
  db 0x64,0x67,0x90
}

macro iaca_end {
  MOV ebx,222
  db 0x64,0x67,0x90
}

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
; in: ymm0 angle in radians
; out: ymm0 sine of ymm0
;      ymm1 cosine of ymm0
falign
sincos:
        VANDPS ymm0, ymm0, [.k_inv_sign_mask]
        VANDPS ymm7, ymm0, [.k_sign_mask]
        VMULPS ymm0, ymm0, [.k_2_div_pi]
        VPXOR ymm3, ymm3, ymm3
        VMOVDQA ymm8, [k_1]
        VMOVAPS ymm4, [k_1_0]
        VCVTTPS2DQ ymm2, ymm0
        VPAND ymm5, ymm8, ymm2
        VPCMPEQD ymm5, ymm5, ymm3
        VMOVDQA ymm1, [k_2]
        VCVTDQ2PS ymm6, ymm2
        VPADDD ymm3, ymm8, ymm2
        VPAND ymm2, ymm2, ymm1
        VPAND ymm3, ymm3, ymm1
        VSUBPS ymm0, ymm0, ymm6
        VPSLLD ymm2, ymm2, 30
        VMINPS ymm0, ymm0, ymm4
        VSUBPS ymm4, ymm4, ymm0
        VPSLLD ymm3, ymm3, 30
        VXORPS ymm2, ymm2, ymm7
        VANDPS ymm6, ymm4, ymm5
        VANDNPS ymm7, ymm5, ymm0
        VANDPS ymm0, ymm0, ymm5
        VANDNPS ymm5, ymm5, ymm4
        VMOVAPS ymm8, [.k_p3]
        VMOVAPS ymm9, [.k_p2]
        VMOVAPS ymm10, [.k_p1]
        VMOVAPS ymm11, [.k_p0]
        VORPS ymm6, ymm6, ymm7
        VORPS ymm0, ymm0, ymm5
        VORPS ymm1, ymm0, ymm2
        VORPS ymm7, ymm6, ymm3
        VMULPS ymm2, ymm0, ymm0
        VMULPS ymm3, ymm6, ymm6
        VFMADD132PS ymm0, ymm9, ymm8
        VFMADD132PS ymm6, ymm9, ymm8
        VFMADD132PS ymm0, ymm10, ymm2
        VFMADD132PS ymm6, ymm10, ymm3
        VFMADD132PS ymm0, ymm11, ymm2
        VFMADD132PS ymm6, ymm11, ymm3
        VMULPS ymm0, ymm0, ymm1
        VMULPS ymm1, ymm6, ymm7
        RET

; in: ymm0,ymm1,ymm2 position
; out: ymm0 distance to the nearest object
macro nearest_distance {
        VBROADCASTSS ymm3, [object.param_x]
        VBROADCASTSS ymm6, [object.param_x+4]
        VBROADCASTSS ymm9, [object.param_x+8]
        VBROADCASTSS ymm4, [object.param_y]
        VBROADCASTSS ymm7, [object.param_y+4]
        VBROADCASTSS ymm10, [object.param_y+8]
        VBROADCASTSS ymm5, [object.param_z]
        VBROADCASTSS ymm8, [object.param_z+4]
        VBROADCASTSS ymm11, [object.param_z+8]
        VSUBPS ymm3, ymm0, ymm3
        VSUBPS ymm6, ymm0, ymm6
        VSUBPS ymm9, ymm0, ymm9
        VSUBPS ymm4, ymm1, ymm4
        VSUBPS ymm7, ymm1, ymm7
        VSUBPS ymm10, ymm1, ymm10
        VSUBPS ymm5, ymm2, ymm5
        VSUBPS ymm8, ymm2, ymm8
        VSUBPS ymm11, ymm2, ymm11
        VMULPS ymm3, ymm3, ymm3
        VMULPS ymm6, ymm6, ymm6
        VMULPS ymm9, ymm9, ymm9
        VFMADD231PS ymm3, ymm4, ymm4
        VFMADD231PS ymm6, ymm7, ymm7
        VFMADD231PS ymm9, ymm10, ymm10
        VFMADD231PS ymm3, ymm5, ymm5
        VFMADD231PS ymm6, ymm8, ymm8
        VFMADD231PS ymm9, ymm11, ymm11
        VBROADCASTSS ymm5, [object.param_w+12]
        VADDPS ymm5, ymm1, ymm5
        VRSQRTPS ymm3, ymm3
        VRSQRTPS ymm6, ymm6
        VRSQRTPS ymm9, ymm9
        VRCPPS ymm3, ymm3
        VRCPPS ymm6, ymm6
        VRCPPS ymm9, ymm9
        VBROADCASTSS ymm10, [object.param_w]
        VBROADCASTSS ymm11, [object.param_w+4]
        VBROADCASTSS ymm12, [object.param_w+8]
        VSUBPS ymm3, ymm3, ymm10
        VSUBPS ymm6, ymm6, ymm11
        VSUBPS ymm9, ymm9, ymm12
        VMINPS ymm0, ymm5, ymm3
        VMINPS ymm0, ymm0, ymm6
        VMINPS ymm0, ymm0, ymm9
}
; in: ymm0,ymm1,ymm2 position
; out: ymm0 id of the nearest object
falign
nearest_object:
        VBROADCASTSS ymm3, [object.param_x]
        VBROADCASTSS ymm6, [object.param_x+4]
        VBROADCASTSS ymm9, [object.param_x+8]
        VBROADCASTSS ymm4, [object.param_y]
        VBROADCASTSS ymm7, [object.param_y+4]
        VBROADCASTSS ymm10, [object.param_y+8]
        VBROADCASTSS ymm5, [object.param_z]
        VBROADCASTSS ymm8, [object.param_z+4]
        VBROADCASTSS ymm11, [object.param_z+8]
        VSUBPS ymm3, ymm0, ymm3
        VSUBPS ymm6, ymm0, ymm6
        VSUBPS ymm9, ymm0, ymm9
        VSUBPS ymm4, ymm1, ymm4
        VSUBPS ymm7, ymm1, ymm7
        VSUBPS ymm10, ymm1, ymm10
        VSUBPS ymm5, ymm2, ymm5
        VSUBPS ymm8, ymm2, ymm8
        VSUBPS ymm11, ymm2, ymm11
        VMULPS ymm3, ymm3, ymm3
        VMULPS ymm6, ymm6, ymm6
        VMULPS ymm9, ymm9, ymm9
        VFMADD231PS ymm3, ymm4, ymm4
        VFMADD231PS ymm6, ymm7, ymm7
        VFMADD231PS ymm9, ymm10, ymm10
        VFMADD231PS ymm3, ymm5, ymm5
        VFMADD231PS ymm6, ymm8, ymm8
        VFMADD231PS ymm9, ymm11, ymm11
        VBROADCASTSS ymm5, [object.param_w+12]
        VADDPS ymm5, ymm1, ymm5       ; ymm5 = object3_distance
        VRSQRTPS ymm2, ymm3
        VRSQRTPS ymm3, ymm6
        VRSQRTPS ymm4, ymm9
        VRCPPS ymm2, ymm2
        VRCPPS ymm3, ymm3
        VRCPPS ymm4, ymm4
        VBROADCASTSS ymm10, [object.param_w]
        VBROADCASTSS ymm11, [object.param_w+4]
        VBROADCASTSS ymm12, [object.param_w+8]
        VMOVAPS ymm6, [object.id+_0]
        VMOVAPS ymm7, [object.id+_1]
        VMOVAPS ymm8, [object.id+_2]
        VMOVAPS ymm9, [object.id+_3]
        VSUBPS ymm2, ymm2, ymm10                       ; ymm2 = object0_distance
        VSUBPS ymm3, ymm3, ymm11                       ; ymm3 = object1_distance
        VSUBPS ymm4, ymm4, ymm12                       ; ymm4 = object2_distance
        VCMPLTPS ymm10, ymm5, ymm2
        VMINPS ymm0, ymm5, ymm2
        VBLENDVPS ymm1, ymm6, ymm9, ymm10
        VCMPLTPS ymm10, ymm0, ymm3
        VMINPS ymm0, ymm0, ymm3
        VBLENDVPS ymm1, ymm7, ymm1, ymm10
        VCMPLTPS ymm10, ymm0, ymm4
        VBLENDVPS ymm0, ymm8, ymm1, ymm10
        RET

; in: ymm0,ymm1,ymm2 ray origin                        ; JG46-MT2JDJ8D
;     ymm3,ymm4,ymm5 ray direction
; out: ymm0 distance to the nearest object
;      ymm1 id of the nearest object
;      ymm2,ymm3,ymm4 ray hit position
falign
cast_ray:
        PUSH rsi
        SUB rsp, 10*32+16
        VMOVAPS ymm6, [k_1_0]
        VMOVAPS [rsp+_0], ymm0                        ; [rsp+_0] = ray_org_x
        VMOVAPS [rsp+_1], ymm1                        ; [rsp+_1] = ray_org_y
        VMOVAPS [rsp+_2], ymm2                        ; [rsp+_2] = ray_org_z
        VMOVAPS [rsp+_6], ymm6                        ; [rsp+_6] = distance
        VMOVAPS [rsp+_3], ymm3                        ; [rsp+_3] = ray_dir_x
        VMOVAPS [rsp+_4], ymm4                        ; [rsp+_4] = ray_dir_y
        VMOVAPS [rsp+_5], ymm5                        ; [rsp+_5] = ray_dir_z
        MOV esi, 128
.calign
.march:
        VFMADD231PS ymm0, ymm6, ymm3
        VFMADD231PS ymm1, ymm6, ymm4
        VFMADD231PS ymm2, ymm6, ymm5
        VMOVAPS [rsp+_7], ymm0                        ; [rsp+_7] = pos_x
        VMOVAPS [rsp+_8], ymm1                        ; [rsp+_8] = pos_y
        VMOVAPS [rsp+_9], ymm2                        ; [rsp+_9] = pos_z
        nearest_distance
        VMOVAPS ymm6, [rsp+_6]                        ; ymm6 = distance
        VCMPLTPS ymm7, ymm0, [k_hit_distance]
        VCMPGTPS ymm8, ymm6, [k_view_distance]
        VORPS ymm7, ymm7, ymm8
        VMOVMSKPS eax, ymm7
        CMP eax, 0xff
        JE .march_end
        VANDNPS ymm0, ymm7, ymm0
        VADDPS ymm6, ymm6, ymm0
        VMOVAPS ymm0, [rsp+_0]                        ; ymm0 = ray_org_x
        VMOVAPS ymm1, [rsp+_1]                        ; ymm1 = ray_org_y
        VMOVAPS ymm2, [rsp+_2]                        ; ymm2 = ray_org_z
        VMOVAPS ymm3, [rsp+_3]                        ; ymm3 = ray_dir_x
        VMOVAPS ymm4, [rsp+_4]                        ; ymm4 = ray_dir_y
        VMOVAPS ymm5, [rsp+_5]                        ; ymm5 = ray_dir_z
        VMOVAPS [rsp+_6], ymm6                        ; distance = ymm6
        DEC esi
        JNZ .march
.march_end:
        VMOVAPS ymm0, [rsp+_7]                        ; ymm0 = pos_x
        VMOVAPS ymm1, [rsp+_8]                        ; ymm1 = pos_y
        VMOVAPS ymm2, [rsp+_9]                        ; ymm2 = pos_z
        CALL nearest_object
        VMOVAPS ymm2, [rsp+_7]                        ; ymm2 = pos_x
        VMOVAPS ymm3, [rsp+_8]                        ; ymm3 = pos_y
        VMOVAPS ymm4, [rsp+_9]                        ; ymm4 = pos_z
        VMOVAPS ymm1, ymm0                              ; ymm1 = object_id
        VMOVAPS ymm0, [rsp+_6]                        ; ymm0 = distance
        ADD rsp, 10*32+16
        POP rsi
        RET

; in: ymm0,ymm1,ymm2 ray origin
;     ymm3,ymm4,ymm5 ray direction
; out: ymm0 shadow factor
falign
cast_shadow_ray:
        PUSH rsi
        SUB rsp, 8*32+16
        VMOVAPS ymm6, [k_1_0]
        VMOVAPS [rsp+_7], ymm6            ; [rsp+$0e0] = shadow_factor = 1.0
        VMOVAPS ymm6, [k_0_02]
        VMOVAPS [rsp+_0], ymm0            ; [rsp+$000] = ray_org_x
        VMOVAPS [rsp+_1], ymm1            ; [rsp+$020] = ray_org_y
        VMOVAPS [rsp+_2], ymm2            ; [rsp+$040] = ray_org_z
        VMOVAPS [rsp+_6], ymm6            ; [rsp+$0c0] = distance
        VMOVAPS [rsp+_3], ymm3            ; [rsp+$060] = ray_dir_x
        VMOVAPS [rsp+_4], ymm4            ; [rsp+$080] = ray_dir_y
        VMOVAPS [rsp+_5], ymm5            ; [rsp+$0a0] = ray_dir_z
        MOV esi, 128
.calign
.march:
        VFMADD231PS ymm0, ymm6, ymm3
        VFMADD231PS ymm1, ymm6, ymm4
        VFMADD231PS ymm2, ymm6, ymm5
        nearest_distance
        VMOVAPS ymm6, [rsp+_6]            ; ymm6 = distance
        VCMPLTPS ymm7, ymm0, [k_hit_distance]
        VCMPGTPS ymm8, ymm6, [k_view_distance]
        VORPS ymm7, ymm7, ymm8
        VMOVMSKPS eax, ymm7
        CMP eax, 0xff
        JE .march_end
        VRCPPS ymm10, ymm6
        VMULPS ymm10, ymm0, ymm10
        VMULPS ymm10, ymm10, [k_shadow_hardness]
        VMINPS ymm10, ymm10, [rsp+_7]      ; ymm10 = min(ymm10,shadow_factor)
        VMOVAPS [rsp+_7], ymm10           ; shadow_factor = ymm10
        VANDNPS ymm0, ymm7, ymm0
        VADDPS ymm6, ymm6, ymm0
        VMOVAPS ymm0, [rsp+_0]            ; ymm0 = ray_org_x
        VMOVAPS ymm1, [rsp+_1]            ; ymm1 = ray_org_y
        VMOVAPS ymm2, [rsp+_2]            ; ymm2 = ray_org_z
        VMOVAPS ymm3, [rsp+_3]            ; ymm3 = ray_dir_x
        VMOVAPS ymm4, [rsp+_4]            ; ymm4 = ray_dir_y
        VMOVAPS ymm5, [rsp+_5]            ; ymm5 = ray_dir_z
        VMOVAPS [rsp+_6], ymm6            ; distance = ymm6
        DEC esi
        JNZ .march
.march_end:
        VMOVAPS ymm0, [rsp+_7]            ; ymm0 = shadow_factor
        ADD rsp, 8*32+16
        POP rsi
        RET

; in: ymm2,ymm3,ymm4 position
;     ymm5 k_normal_eps
; out: ymm0,ymm1,ymm2 normal $vector at input position
macro compute_normal {
        VSUBPS ymm0, ymm2, ymm5               ; ymm0 = hit_pos_x-k_normal_pos
        VADDPS ymm6, ymm2, ymm5               ; ymm6 = hit_pos_x+k_normal_eps
        VSUBPS ymm7, ymm3, ymm5               ; ymm7 = hit_pos_y-k_normal_eps
        VADDPS ymm8, ymm3, ymm5               ; ymm8 = hit_pos_y+k_normal_eps
        VSUBPS ymm9, ymm4, ymm5               ; ymm9 = hit_pos_z-k_normal_eps
        VADDPS ymm10, ymm4, ymm5              ; ymm10 = hit_pos_z+k_normal_eps
        VMOVAPS ymm1, ymm3                   ; ymm1 = hit_pos_y
        VMOVAPS ymm2, ymm4                   ; ymm2 = hit_pos_z
        VMOVAPS [rsp+_5], ymm6             ; [rsp+$0a0] = hit_pos_x+k_normal_eps
        VMOVAPS [rsp+_6], ymm7             ; [rsp+$0c0] = hit_pos_y-k_normal_eps
        VMOVAPS [rsp+_7], ymm8             ; [rsp+$0e0] = hit_pos_y+k_normal_eps
        VMOVAPS [rsp+_8], ymm9             ; [rsp+$100] = hit_pos_z-k_normal_eps
        VMOVAPS [rsp+_9], ymm10            ; [rsp+$120] = hit_pos_z+k_normal_eps
        nearest_distance               ; ymm0 = nearest_distance(x-eps,y,z)
        VMOVAPS ymm1, [rsp+_3]             ; ymm1 = hit_pos_y
        VMOVAPS ymm2, [rsp+_4]             ; ymm2 = hit_pos_z
        VMOVAPS [rsp+_10], ymm0             ; [rsp+$140] = nearest_distance(x-eps,y,z)
        VMOVAPS ymm0, [rsp+_5]             ; ymm0 = hit_pos_x+k_normal_eps
        nearest_distance               ; ymm0 = nearest_distance(x+eps,y,z)
        VMOVAPS ymm1, [rsp+_6]             ; ymm1 = hit_pos_y-k_normal_eps
        VMOVAPS ymm2, [rsp+_4]             ; ymm2 = hit_pos_z
        VMOVAPS [rsp+_11], ymm0             ; [rsp+$160] = nearest_distance(x+eps,y,z)
        VMOVAPS ymm0, [rsp+_2]             ; ymm0 = hit_pos_x
        nearest_distance               ; ymm0 = nearest_distance(x,y-eps,z)
        VMOVAPS ymm1, [rsp+_7]             ; ymm1 = hit_pos_y+k_normal_eps
        VMOVAPS ymm2, [rsp+_4]             ; ymm2 = hit_pos_z
        VMOVAPS [rsp+_12], ymm0             ; [rsp+$180] = nearest_distance(x,y-eps,z)
        VMOVAPS ymm0, [rsp+_2]             ; ymm0 = hit_pos_x
        nearest_distance               ; ymm0 = nearest_distance(x,y+eps,z)
        VMOVAPS ymm1, [rsp+_3]             ; ymm1 = hit_pos_y
        VMOVAPS ymm2, [rsp+_8]             ; ymm2 = hit_pos_z-k_normal_eps
        VMOVAPS [rsp+_13], ymm0             ; [rsp+$1a0] = nearest_distance(x,y+eps,z)
        VMOVAPS ymm0, [rsp+_2]             ; ymm0 = hit_pos_x
        nearest_distance               ; ymm0 = nearest_distance(x,y,z-eps)
        VMOVAPS ymm1, [rsp+_3]             ; ymm1 = hit_pos_y
        VMOVAPS ymm2, [rsp+_9]             ; ymm2 = hit_pos_z+k_normal_eps
        VMOVAPS [rsp+_14], ymm0             ; [rsp+$1c0] = nearest_distance(x,y,z-eps)
        VMOVAPS ymm0, [rsp+_2]             ; ymm0 = hit_pos_x
        nearest_distance               ; ymm0 = nearest_distance(x,y,z+eps)
        VSUBPS ymm2, ymm0, [rsp+_14]
        VMOVAPS ymm0, [rsp+_11]
        VMOVAPS ymm1, [rsp+_13]
        VSUBPS ymm0, ymm0, [rsp+_10]
        VSUBPS ymm1, ymm1, [rsp+_12]         ; (ymm0,ymm1,ymm2) = normal_vector
}
; in: ymm0,ymm1,ymm2 ray origin
;     ymm3,ymm4,ymm5 ray direction
; out: ymm0,ymm1,ymm2 rgb color
falign
compute_color:
        SUB rsp, 16*32+24
        CALL cast_ray
        VMOVAPS ymm5, [k_view_distance]
        VCMPLTPS ymm11, ymm0, ymm5                    ; ymm11 = hit_mask
        VMOVMSKPS eax, ymm11
        TEST eax, eax
        JZ .no_hit
        VMOVAPS ymm7, [k_1_0]
        VRCPPS ymm5, ymm5
        VMULPS ymm5, ymm0, ymm5
        VSUBPS ymm5, ymm7, ymm5
        VMOVAPS [rsp+_15], ymm5                     ; [rsp+$1e0] = fog_factor
        VMOVAPS ymm5, [k_normal_eps]
        VMOVAPS [rsp+_1], ymm1                     ; [rsp+$020] = hit_id
        VMOVAPS [rsp+_2], ymm2                     ; [rsp+$040] = pos_x
        VMOVAPS [rsp+_3], ymm3                     ; [rsp+$060] = pos_y
        VMOVAPS [rsp+_4], ymm4                     ; [rsp+$080] = pos_z
        VMOVAPS [rsp+_0], ymm11                    ; [rsp+$000] = hit_mask
        compute_normal                                 ; (ymm0,ymm1,ymm2) = normal_vector
        VMOVAPS ymm9, [rsp+_2]                     ; ymm9 = hit_pos_x
        VMOVAPS ymm10, [rsp+_3]                    ; ymm10 = hit_pos_y
        VMOVAPS ymm11, [rsp+_4]                    ; ymm11 = hit_pos_z
        VBROADCASTSS ymm3, [light0_position]
        VBROADCASTSS ymm4, [light0_position+4]
        VBROADCASTSS ymm5, [light0_position+8]
        VBROADCASTSS ymm6, [light1_position]
        VBROADCASTSS ymm7, [light1_position+4]
        VBROADCASTSS ymm8, [light1_position+8]
        VSUBPS ymm3, ymm3, ymm9
        VSUBPS ymm4, ymm4, ymm10
        VSUBPS ymm5, ymm5, ymm11                      ; (ymm3,ymm4,ymm5) = light0_vector
        VSUBPS ymm6, ymm6, ymm9
        VSUBPS ymm7, ymm7, ymm10
        VSUBPS ymm8, ymm8, ymm11                      ; (ymm6,ymm7,ymm8) = light1_vector
        VMULPS ymm12, ymm0, ymm0
        VMULPS ymm13, ymm3, ymm3
        VMULPS ymm14, ymm6, ymm6
        VFMADD231PS ymm12, ymm1, ymm1
        VFMADD231PS ymm13, ymm4, ymm4
        VFMADD231PS ymm14, ymm7, ymm7
        VFMADD231PS ymm12, ymm2, ymm2
        VFMADD231PS ymm13, ymm5, ymm5
        VFMADD231PS ymm14, ymm8, ymm8
        VRSQRTPS ymm12, ymm12
        VRSQRTPS ymm13, ymm13
        VRSQRTPS ymm14, ymm14
        VMULPS ymm0, ymm0, ymm12
        VMULPS ymm1, ymm1, ymm12
        VMULPS ymm2, ymm2, ymm12           ; (ymm0,ymm1,ymm2) = normalize(normal_vector)
        VMULPS ymm3, ymm3, ymm13
        VMULPS ymm4, ymm4, ymm13
        VMULPS ymm5, ymm5, ymm13           ; (ymm3,ymm4,ymm5) = normalize(light0_vector)
        VMULPS ymm6, ymm6, ymm14
        VMULPS ymm7, ymm7, ymm14
        VMULPS ymm8, ymm8, ymm14           ; (ymm6,ymm7,ymm8) = normalize(light1_vector)
        VXORPS ymm14, ymm14, ymm14
        VMULPS ymm12, ymm0, ymm3
        VMULPS ymm13, ymm0, ymm6
        VFMADD231PS ymm12, ymm1, ymm4
        VFMADD231PS ymm13, ymm1, ymm7
        VFMADD231PS ymm12, ymm2, ymm5
        VFMADD231PS ymm13, ymm2, ymm8
        VMAXPS ymm12, ymm12, ymm14                       ; ymm12 = n_dot_l0
        VMAXPS ymm13, ymm13, ymm14                       ; ymm13 = n_dot_l1
        VMOVAPS [rsp+_5], ymm12                       ; [rsp+$0a0] = n_dot_l0
        VMOVAPS [rsp+_6], ymm13                       ; [rsp+$0c0] = n_dot_l1
        VMOVAPS ymm0, ymm9
        VMOVAPS ymm1, ymm10
        VMOVAPS ymm2, ymm11
        VMOVAPS [rsp+_7], ymm6                        ; [rsp+$0e0] = light1_vec_x
        VMOVAPS [rsp+_8], ymm7                        ; [rsp+$100] = light1_vec_y
        VMOVAPS [rsp+_9], ymm8                        ; [rsp+$120] = light1_vec_z
        CALL cast_shadow_ray
        VMOVAPS [rsp+_10], ymm0                        ; [rsp+$140] = light0_shadow
        VMOVAPS ymm0, [rsp+_2]                        ; ymm0 = hit_pos_x
        VMOVAPS ymm1, [rsp+_3]                        ; ymm1 = hit_pos_y
        VMOVAPS ymm2, [rsp+_4]                        ; ymm2 = hit_pos_z
        VMOVAPS ymm3, [rsp+_7]                        ; ymm3 = light1_vec_x
        VMOVAPS ymm4, [rsp+_8]                        ; ymm4 = light1_vec_y
        VMOVAPS ymm5, [rsp+_9]                        ; ymm5 = light1_vec_z
        CALL cast_shadow_ray
        VMULPS ymm7, ymm0, [rsp+_6]                    ; ymm7 = ymm0 * n_dot_l1
        VMOVAPS ymm6, [rsp+_5]                        ; ymm6 = n_dot_l0
        VMULPS ymm6, ymm6, [rsp+_10]                    ; ymm6 = ymm6 * light0_shadow
        VBROADCASTSS ymm1, [light1_power]
        VMULPS ymm7, ymm7, ymm1
        VBROADCASTSS ymm1, [light0_power]
        VMULPS ymm6, ymm6, ymm1
        VADDPS ymm6, ymm6, ymm7
        VMOVAPS ymm7, [rsp+_15]                        ; ymm7 = fog_factor
        VBROADCASTSS ymm8, [ambient]
        VMOVAPS ymm11, [rsp+_0]                       ; ymm11 = hit_mask
        LEA rax, [object]
        VMOVDQA ymm1, [rsp+_1]                        ; ymm1 = hit_id
        VPCMPEQD ymm2, ymm2, ymm2
        VGATHERDPS ymm3, [rax+ymm1*4+(object.red-object)], ymm2
        VPCMPEQD ymm2, ymm2, ymm2
        VGATHERDPS ymm4, [rax+ymm1*4+(object.green-object)], ymm2
        VPCMPEQD ymm2, ymm2, ymm2
        VGATHERDPS ymm5, [rax+ymm1*4+(object.blue-object)], ymm2
        VFMADD132PS ymm3, ymm8, ymm6
        VFMADD132PS ymm4, ymm8, ymm6
        VFMADD132PS ymm5, ymm8, ymm6
        VMULPS ymm3, ymm3, ymm7
        VMULPS ymm4, ymm4, ymm7
        VMULPS ymm5, ymm5, ymm7
        VBROADCASTSS ymm7, [k_background_color]
        VBROADCASTSS ymm8, [k_background_color+4]
        VBROADCASTSS ymm9, [k_background_color+8]
        VBLENDVPS ymm0, ymm7, ymm3, ymm11
        VBLENDVPS ymm1, ymm8, ymm4, ymm11
        VBLENDVPS ymm2, ymm9, ymm5, ymm11
        ADD rsp, 16*32+24
        RET
.calign
.no_hit:
        VBROADCASTSS ymm0, [k_background_color]
        VBROADCASTSS ymm1, [k_background_color+4]
        VBROADCASTSS ymm2, [k_background_color+8]
        ADD rsp, 16*32+24
        RET

; Generate image tile by tile. Take one tile from the pool, compute
; it's color and then take next tile, and so on. Finish when all tiles
; are computed. This function is dispatched from all worker threads in
; parallel.
falign
generate_image:
        PUSH rsi rdi rbx rbp r12 r13 r14 r15
        SUB rsp, 24
.for_each_tile:
        MOV eax, 1
        LOCK XADD [tileidx], eax
        CMP eax, k_tile_count
        JAE .ret
        XOR edx, edx
        MOV ecx, k_tile_x_count
        DIV ecx                         ; eax = (k_tile_count/k_tile_x_count), edx = (k_tile_count%k_tile_x_count)
        MOV r14d, k_tile_width
        MOV r15d, k_tile_height
        IMUL edx, r14d
        IMUL eax, r15d
        MOV r12d, edx                                  ; r12d = x0
        MOV r13d, eax                                  ; r13d = y0
        ADD r14d, r12d                                 ; r14d = x1 = x0 + k_tile_width
        ADD r15d, r13d                                 ; r15d = y1 = y0 + k_tile_height
        IMUL eax, k_win_width
        ADD eax, edx
        SHL eax, 2
        MOV rbx, [displayptr]
        ADD rbx, rax
.calign
.for_each_4x2:
        VXORPS xmm0, xmm0, xmm0
        VXORPS xmm1, xmm1, xmm1
        MOV eax, r12d
        MOV edx, r13d
        SUB eax, k_win_width/2
        SUB edx, k_win_height/2
        VCVTSI2SS xmm0, xmm0, eax        ; (0, 0, 0, xf = (float)(x - k_win_width / 2))
        VCVTSI2SS xmm1, xmm1, edx        ; (0, 0, 0, yf = (float)(y - k_win_height / 2))
        VBROADCASTSS ymm0, xmm0         ; ymm0 = (xf ... xf)
        VBROADCASTSS ymm1, xmm1         ; ymm1 = (yf ... yf)
        VADDPS ymm0, ymm0, [.k_x_offset]
        VADDPS ymm1, ymm1, [.k_y_offset]
        VMOVAPS ymm2, [.k_rd_z]
        VMULPS ymm0, ymm0, [.k_win_width_rcp]
        VMULPS ymm1, ymm1, [.k_win_height_rcp]
        VMULPS ymm3, ymm0, [eye_xaxis+$000]
        VMULPS ymm6, ymm0, [eye_xaxis+$020]
        VMULPS ymm9, ymm0, [eye_xaxis+$040]
        VFMADD231PS ymm3, ymm1, [eye_yaxis+$000]
        VFMADD231PS ymm6, ymm1, [eye_yaxis+$020]
        VFMADD231PS ymm9, ymm1, [eye_yaxis+$040]
        VFMADD231PS ymm3, ymm2, [eye_zaxis+$000]
        VFMADD231PS ymm6, ymm2, [eye_zaxis+$020]
        VFMADD231PS ymm9, ymm2, [eye_zaxis+$040]
        VBROADCASTSS ymm0, [eye_position]
        VBROADCASTSS ymm1, [eye_position+4]
        VBROADCASTSS ymm2, [eye_position+8]
        VMULPS ymm10, ymm3, ymm3
        VMULPS ymm11, ymm6, ymm6
        VMULPS ymm12, ymm9, ymm9
        VADDPS ymm10, ymm10, ymm11
        VADDPS ymm10, ymm10, ymm12
        VRSQRTPS ymm10, ymm10
        VMULPS ymm3, ymm3, ymm10
        VMULPS ymm4, ymm6, ymm10
        VMULPS ymm5, ymm9, ymm10
        CALL compute_color
        VXORPS ymm7, ymm7, ymm7                          ; ymm7 = (0 ... 0)
        VMOVAPS ymm8, [k_1_0]                           ; ymm8 = (1.0 ... 1.0)
        VMOVAPS ymm9, [k_255_0]                         ; ymm9 = (255.0 ... 255.0)
        VMAXPS ymm0, ymm0, ymm7
        VMAXPS ymm1, ymm1, ymm7
        VMAXPS ymm2, ymm2, ymm7
        VMINPS ymm0, ymm0, ymm8
        VMINPS ymm1, ymm1, ymm8
        VMINPS ymm2, ymm2, ymm8
        VMULPS ymm0, ymm0, ymm9
        VMULPS ymm1, ymm1, ymm9
        VMULPS ymm2, ymm2, ymm9
        VCVTTPS2DQ ymm0, ymm0
        VCVTTPS2DQ ymm1, ymm1
        VCVTTPS2DQ ymm2, ymm2
        VPSLLD ymm0, ymm0, 16
        VPSLLD ymm1, ymm1, 8
        VPOR ymm0, ymm0, ymm1
        VPOR ymm0, ymm0, ymm2
        VMOVDQA [rbx], xmm0
        VEXTRACTI128 [rbx+k_win_width*4], ymm0, 1
        ADD rbx, 16
        ADD r12d, 4
        CMP r12d, r14d
        JB .for_each_4x2
        ADD rbx, 2*(k_win_width*4)-k_tile_width*4
        SUB r12d, k_tile_width
        ADD r13d, 2
        CMP r13d, r15d
        JB .for_each_4x2
        JMP .for_each_tile
.ret:   ADD rsp, 24
        POP r15 r14 r13 r12 rbp rbx rdi rsi
        RET

falign
update_state:
        SUB rsp, 24
        VXORPS xmm0, xmm0, xmm0
        VBROADCASTSS ymm0, xmm0
        VMULPS ymm0, ymm0, [k_0_5]
        CALL sincos
        VMOVAPS ymm2, [k_camera_radius]
        VMULPS ymm0, ymm0, ymm2
        VMULPS ymm1, ymm1, ymm2
        VMOVSS [eye_position], xmm0
        VMOVSS [eye_position+8], xmm1
        VXORPS xmm0, xmm0, xmm0
        VCVTSD2SS xmm0, xmm0, [time]
        VBROADCASTSS ymm0, xmm0
        VMULPS ymm0, ymm0, [k_0_5]
        CALL sincos
        VMOVAPS ymm2, [k_sphere_radius]
        VMULPS ymm0, ymm0, ymm2
        VMULPS ymm1, ymm1, ymm2
        VMOVSS [object.param_x+4], xmm1
        VMOVSS [object.param_z+4], xmm0
        VXORPS ymm2, ymm2, ymm2
        VSUBPS ymm0, ymm2, ymm0
        VSUBPS ymm1, ymm2, ymm1
        VMOVSS [object.param_x+8], xmm1
        VMOVSS [object.param_z+8], xmm0
        VBROADCASTSS ymm0, [eye_position]             ; ymm0 = eye x pos
        VBROADCASTSS ymm3, [eye_focus]
        VBROADCASTSS ymm1, [eye_position+4]             ; ymm1 = eye y pos
        VBROADCASTSS ymm4, [eye_focus+4]
        VBROADCASTSS ymm2, [eye_position+8]             ; ymm2 = eye z pos
        VBROADCASTSS ymm5, [eye_focus+8]
        VSUBPS ymm3, ymm0, ymm3
        VSUBPS ymm4, ymm1, ymm4
        VSUBPS ymm5, ymm2, ymm5
        VMULPS ymm6, ymm3, ymm3
        VMULPS ymm7, ymm4, ymm4
        VMULPS ymm8, ymm5, ymm5
        VADDPS ymm6, ymm6, ymm7
        VADDPS ymm6, ymm6, ymm8
        VRSQRTPS ymm6, ymm6
        VMULPS ymm3, ymm3, ymm6
        VMULPS ymm4, ymm4, ymm6
        VMULPS ymm5, ymm5, ymm6                    ; (ymm3,ymm4,ymm5) = normalized(iz)
        VMOVAPS [eye_zaxis+$000], ymm3
        VMOVAPS [eye_zaxis+$020], ymm4
        VMOVAPS [eye_zaxis+$040], ymm5
        VXORPS      ymm8,ymm8,ymm8
        VSUBPS      ymm8,ymm8,ymm3
        VXORPS      ymm7,ymm7,ymm7
        VMOVAPS     ymm6,ymm5                        ; (ymm6,ymm7,ymm8) = ix
        VMULPS      ymm9,ymm8,ymm8
        VMULPS      ymm10,ymm6,ymm6
        VADDPS      ymm9,ymm9,ymm10
        VRSQRTPS    ymm9,ymm9
        VMULPS      ymm6,ymm6,ymm9
        VMULPS      ymm8,ymm8,ymm9                    ; (ymm6,ymm7,ymm8) = normalized(ix)
        VMOVAPS     [eye_xaxis+$000],ymm6
        VMOVAPS     [eye_xaxis+$020],ymm7
        VMOVAPS     [eye_xaxis+$040],ymm8
        VMULPS      ymm9,ymm5,ymm7
        VMULPS      ymm10,ymm3,ymm8
        VMULPS      ymm11,ymm4,ymm6
        VFMSUB231PS ymm9,ymm4,ymm8
        VFMSUB231PS ymm10,ymm5,ymm6
        VFMSUB231PS ymm11,ymm3,ymm7              ; (ymm9,ymm10,ymm11) = iy
        VMULPS      ymm12,ymm9,ymm9
        VMULPS      ymm13,ymm10,ymm10
        VMULPS      ymm14,ymm11,ymm11
        VADDPS      ymm12,ymm12,ymm13
        VADDPS      ymm12,ymm12,ymm14
        VRSQRTPS    ymm12,ymm12
        VMULPS      ymm9,ymm9,ymm12
        VMULPS      ymm10,ymm10,ymm12
        VMULPS      ymm11,ymm11,ymm12                 ; (ymm9,ymm10,ymm11) = normalized(iy)
        VMOVAPS     [eye_yaxis+$000],ymm9
        VMOVAPS     [eye_yaxis+$020],ymm10
        VMOVAPS     [eye_yaxis+$040],ymm11
        ADD         rsp,24
        RET

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

  k_thrd_max_count = 128

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
  light0_position dd 10.0, 10.0, 10.0
  light0_power dd 0.9
  light1_position dd 5.0, 20.0, -15.0
  light1_power dd 0.6
  ambient dd 0.1

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
