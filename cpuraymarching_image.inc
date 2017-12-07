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
        VBROADCASTSS ymm3, [object.param_x+0]
        VBROADCASTSS ymm6, [object.param_x+4]
        VBROADCASTSS ymm9, [object.param_x+8]
        VBROADCASTSS ymm4, [object.param_y+0]
        VBROADCASTSS ymm7, [object.param_y+4]
        VBROADCASTSS ymm10, [object.param_y+8]
        VBROADCASTSS ymm5, [object.param_z+0]
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
        VBROADCASTSS ymm10, [object.param_w+0]
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
        VBROADCASTSS ymm3, [object.param_x+0]
        VBROADCASTSS ymm6, [object.param_x+4]
        VBROADCASTSS ymm9, [object.param_x+8]
        VBROADCASTSS ymm4, [object.param_y+0]
        VBROADCASTSS ymm7, [object.param_y+4]
        VBROADCASTSS ymm10, [object.param_y+8]
        VBROADCASTSS ymm5, [object.param_z+0]
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
        VBROADCASTSS ymm10, [object.param_w+0]
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
macro calc_normal {
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
align 32
compute_color:
        SUB         rsp,16*32+24
        CALL        cast_ray
        VMOVAPS     ymm5,[k_view_distance]
        VCMPLTPS    ymm11,ymm0,ymm5                    ; ymm11 = hit_mask
        VMOVMSKPS   eax,ymm11
        TEST        eax,eax
        JZ          .no_hit
        VMOVAPS     ymm7,[k_1_0]
        VRCPPS      ymm5,ymm5
        VMULPS      ymm5,ymm0,ymm5
        VSUBPS      ymm5,ymm7,ymm5
        VMOVAPS     [rsp+$1e0],ymm5                     ; [rsp+$1e0] = fog_factor
        VMOVAPS     ymm5,[k_normal_eps]
        VMOVAPS     [rsp+$020],ymm1                     ; [rsp+$020] = hit_id
        VMOVAPS     [rsp+$040],ymm2                     ; [rsp+$040] = pos_x
        VMOVAPS     [rsp+$060],ymm3                     ; [rsp+$060] = pos_y
        VMOVAPS     [rsp+$080],ymm4                     ; [rsp+$080] = pos_z
        VMOVAPS     [rsp+$000],ymm11                    ; [rsp+$000] = hit_mask
        calc_normal                                 ; (ymm0,ymm1,ymm2) = normal_vector
        VMOVAPS     ymm9,[rsp+$040]                     ; ymm9 = hit_pos_x
        VMOVAPS     ymm10,[rsp+$060]                    ; ymm10 = hit_pos_y
        VMOVAPS     ymm11,[rsp+$080]                    ; ymm11 = hit_pos_z
        VMOVAPS     ymm3,[light0_position+$000]
        VMOVAPS     ymm4,[light0_position+$020]
        VMOVAPS     ymm5,[light0_position+$040]
        VMOVAPS     ymm6,[light1_position+$000]
        VMOVAPS     ymm7,[light1_position+$020]
        VMOVAPS     ymm8,[light1_position+$040]
        VSUBPS      ymm3,ymm3,ymm9
        VSUBPS      ymm4,ymm4,ymm10
        VSUBPS      ymm5,ymm5,ymm11                      ; (ymm3,ymm4,ymm5) = light0_vector
        VSUBPS      ymm6,ymm6,ymm9
        VSUBPS      ymm7,ymm7,ymm10
        VSUBPS      ymm8,ymm8,ymm11                      ; (ymm6,ymm7,ymm8) = light1_vector
        VMULPS      ymm12,ymm0,ymm0
        VMULPS      ymm13,ymm3,ymm3
        VMULPS      ymm14,ymm6,ymm6
        VFMADD231PS ymm12,ymm1,ymm1
        VFMADD231PS ymm13,ymm4,ymm4
        VFMADD231PS ymm14,ymm7,ymm7
        VFMADD231PS ymm12,ymm2,ymm2
        VFMADD231PS ymm13,ymm5,ymm5
        VFMADD231PS ymm14,ymm8,ymm8
        VRSQRTPS    ymm12,ymm12
        VRSQRTPS    ymm13,ymm13
        VRSQRTPS    ymm14,ymm14
        VMULPS      ymm0,ymm0,ymm12
        VMULPS      ymm1,ymm1,ymm12
        VMULPS      ymm2,ymm2,ymm12           ; (ymm0,ymm1,ymm2) = normalize(normal_vector)
        VMULPS      ymm3,ymm3,ymm13
        VMULPS      ymm4,ymm4,ymm13
        VMULPS      ymm5,ymm5,ymm13           ; (ymm3,ymm4,ymm5) = normalize(light0_vector)
        VMULPS      ymm6,ymm6,ymm14
        VMULPS      ymm7,ymm7,ymm14
        VMULPS      ymm8,ymm8,ymm14           ; (ymm6,ymm7,ymm8) = normalize(light1_vector)
        VXORPS      ymm14,ymm14,ymm14
        VMULPS      ymm12,ymm0,ymm3
        VMULPS      ymm13,ymm0,ymm6
        VFMADD231PS ymm12,ymm1,ymm4
        VFMADD231PS ymm13,ymm1,ymm7
        VFMADD231PS ymm12,ymm2,ymm5
        VFMADD231PS ymm13,ymm2,ymm8
        VMAXPS      ymm12,ymm12,ymm14                       ; ymm12 = n_dot_l0
        VMAXPS      ymm13,ymm13,ymm14                       ; ymm13 = n_dot_l1
        VMOVAPS     [rsp+$0a0],ymm12                       ; [rsp+$0a0] = n_dot_l0
        VMOVAPS     [rsp+$0c0],ymm13                       ; [rsp+$0c0] = n_dot_l1
        VMOVAPS     ymm0,ymm9
        VMOVAPS     ymm1,ymm10
        VMOVAPS     ymm2,ymm11
        VMOVAPS     [rsp+$0e0],ymm6                        ; [rsp+$0e0] = light1_vec_x
        VMOVAPS     [rsp+$100],ymm7                        ; [rsp+$100] = light1_vec_y
        VMOVAPS     [rsp+$120],ymm8                        ; [rsp+$120] = light1_vec_z
        CALL        cast_shadow_ray
        VMOVAPS     [rsp+$140],ymm0                        ; [rsp+$140] = light0_shadow
        VMOVAPS     ymm0,[rsp+$040]                        ; ymm0 = hit_pos_x
        VMOVAPS     ymm1,[rsp+$060]                        ; ymm1 = hit_pos_y
        VMOVAPS     ymm2,[rsp+$080]                        ; ymm2 = hit_pos_z
        VMOVAPS     ymm3,[rsp+$0e0]                        ; ymm3 = light1_vec_x
        VMOVAPS     ymm4,[rsp+$100]                        ; ymm4 = light1_vec_y
        VMOVAPS     ymm5,[rsp+$120]                        ; ymm5 = light1_vec_z
        CALL        cast_shadow_ray
        VMULPS      ymm7,ymm0,[rsp+$0c0]                    ; ymm7 = ymm0 * n_dot_l1
        VMOVAPS     ymm6,[rsp+$0a0]                        ; ymm6 = n_dot_l0
        VMULPS      ymm6,ymm6,[rsp+$140]                    ; ymm6 = ymm6 * light0_shadow
        VMULPS      ymm7,ymm7,[light1_power]
        VMULPS      ymm6,ymm6,[light0_power]
        VADDPS      ymm6,ymm6,ymm7
        VMOVAPS     ymm7,[rsp+$1e0]                        ; ymm7 = fog_factor
        VMOVAPS     ymm8,[ambient]
        VMOVAPS     ymm11,[rsp+$000]                       ; ymm11 = hit_mask
        LEA         rax,[object]
        VMOVDQA     ymm1,[rsp+$020]                        ; ymm1 = hit_id
        VPCMPEQD    ymm2,ymm2,ymm2
        VGATHERDPS  ymm3,[rax+ymm1*4+(object.red-object)],ymm2
        VPCMPEQD    ymm2,ymm2,ymm2
        VGATHERDPS  ymm4,[rax+ymm1*4+(object.green-object)],ymm2
        VPCMPEQD    ymm2,ymm2,ymm2
        VGATHERDPS  ymm5,[rax+ymm1*4+(object.blue-object)],ymm2
        VFMADD132PS ymm3,ymm8,ymm6
        VFMADD132PS ymm4,ymm8,ymm6
        VFMADD132PS ymm5,ymm8,ymm6
        VMULPS      ymm3,ymm3,ymm7
        VMULPS      ymm4,ymm4,ymm7
        VMULPS      ymm5,ymm5,ymm7
        VBROADCASTSS ymm7,[k_background_color]
        VBROADCASTSS ymm8,[k_background_color+4]
        VBROADCASTSS ymm9,[k_background_color+8]
        VBLENDVPS   ymm0,ymm7,ymm3,ymm11
        VBLENDVPS   ymm1,ymm8,ymm4,ymm11
        VBLENDVPS   ymm2,ymm9,ymm5,ymm11
        ADD         rsp,16*32+24
        RET
.calign
.no_hit:
        VBROADCASTSS ymm0,[k_background_color]
        VBROADCASTSS ymm1,[k_background_color+4]
        VBROADCASTSS ymm2,[k_background_color+8]
        ADD         rsp,16*32+24
        RET
;=============================================================================
; Generate image tile by tile. Take one tile from the pool, compute
; it's color and then take next tile, and so on. Finish when all tiles
; are computed. This function is dispatched from all worker threads in
; parallel.
align 32
generate_image:
;-----------------------------------------------------------------------------
        PUSH        rsi rdi rbx rbp r12 r13 r14 r15
        SUB         rsp,24
  .for_each_tile:
        MOV         eax,1
        LOCK XADD   [tileidx],eax
        CMP         eax,k_tile_count
        JAE         .return
        XOR         edx,edx
        MOV         ecx,k_tile_x_count
        DIV         ecx
        ; eax = (k_tile_count / k_tile_x_count)
        ; edx = (k_tile_count % k_tile_x_count)
        MOV         r14d,k_tile_width
        MOV         r15d,k_tile_height
        IMUL        edx,r14d
        IMUL        eax,r15d
        ; eax = (k_tile_count / k_tile_x_count) * k_tile_height
        ; edx = (k_tile_count % k_tile_x_count) * k_tile_width
        MOV         r12d,edx                                  ; r12d = x0
        MOV         r13d,eax                                  ; r13d = y0
        ADD         r14d,r12d                                 ; r14d = x1 = x0 + k_tile_width
        ADD         r15d,r13d                                 ; r15d = y1 = y0 + k_tile_height
        IMUL        eax,k_win_width
        ADD         eax,edx
        SHL         eax,2
        MOV         rbx,[displayptr]
        ADD         rbx,rax
  align 32
  .for_each_4x2:
        VXORPS      xmm0,xmm0,xmm0
        VXORPS      xmm1,xmm1,xmm1
        MOV         eax,r12d
        MOV         edx,r13d
        SUB         eax,k_win_width/2
        SUB         edx,k_win_height/2
        VCVTSI2SS   xmm0,xmm0,eax        ; (0, 0, 0, xf = (float)(x - k_win_width / 2))
        VCVTSI2SS   xmm1,xmm1,edx        ; (0, 0, 0, yf = (float)(y - k_win_height / 2))
        VBROADCASTSS ymm0,xmm0         ; ymm0 = (xf ... xf)
        VBROADCASTSS ymm1,xmm1         ; ymm1 = (yf ... yf)
        VADDPS      ymm0,ymm0,[.k_x_offset]
        VADDPS      ymm1,ymm1,[.k_y_offset]
        VMOVAPS     ymm2,[.k_rd_z]
        VMULPS      ymm0,ymm0,[.k_win_width_rcp]
        VMULPS      ymm1,ymm1,[.k_win_height_rcp]
        VMULPS      ymm3,ymm0,[eye_xaxis+$000]
        VMULPS      ymm6,ymm0,[eye_xaxis+$020]
        VMULPS      ymm9,ymm0,[eye_xaxis+$040]
        VFMADD231PS ymm3,ymm1,[eye_yaxis+$000]
        VFMADD231PS ymm6,ymm1,[eye_yaxis+$020]
        VFMADD231PS ymm9,ymm1,[eye_yaxis+$040]
        VFMADD231PS ymm3,ymm2,[eye_zaxis+$000]
        VFMADD231PS ymm6,ymm2,[eye_zaxis+$020]
        VFMADD231PS ymm9,ymm2,[eye_zaxis+$040]
        VBROADCASTSS ymm0,[eye_position+0]
        VBROADCASTSS ymm1,[eye_position+4]
        VBROADCASTSS ymm2,[eye_position+8]
        VMULPS      ymm10,ymm3,ymm3
        VMULPS      ymm11,ymm6,ymm6
        VMULPS      ymm12,ymm9,ymm9
        VADDPS      ymm10,ymm10,ymm11
        VADDPS      ymm10,ymm10,ymm12
        VRSQRTPS    ymm10,ymm10
        VMULPS      ymm3,ymm3,ymm10
        VMULPS      ymm4,ymm6,ymm10
        VMULPS      ymm5,ymm9,ymm10
        CALL        compute_color
        VXORPS      ymm7,ymm7,ymm7                          ; ymm7 = (0 ... 0)
        VMOVAPS     ymm8,[k_1_0]                           ; ymm8 = (1.0 ... 1.0)
        VMOVAPS     ymm9,[k_255_0]                         ; ymm9 = (255.0 ... 255.0)
        VMAXPS      ymm0,ymm0,ymm7
        VMAXPS      ymm1,ymm1,ymm7
        VMAXPS      ymm2,ymm2,ymm7
        VMINPS      ymm0,ymm0,ymm8
        VMINPS      ymm1,ymm1,ymm8
        VMINPS      ymm2,ymm2,ymm8
        VMULPS      ymm0,ymm0,ymm9
        VMULPS      ymm1,ymm1,ymm9
        VMULPS      ymm2,ymm2,ymm9
        VCVTTPS2DQ  ymm0,ymm0
        VCVTTPS2DQ  ymm1,ymm1
        VCVTTPS2DQ  ymm2,ymm2
        VPSLLD      ymm0,ymm0,16
        VPSLLD      ymm1,ymm1,8
        VPOR        ymm0,ymm0,ymm1
        VPOR        ymm0,ymm0,ymm2
        VMOVDQA     [rbx],xmm0
        VEXTRACTI128 [rbx+k_win_width*4],ymm0,1
        ADD         rbx,16
        ADD         r12d,4
        CMP         r12d,r14d
        JB          .for_each_4x2
        ADD         rbx,2*(k_win_width*4)-k_tile_width*4
        SUB         r12d,k_tile_width
        ADD         r13d,2
        CMP         r13d,r15d
        JB          .for_each_4x2
        JMP         .for_each_tile
  .return:
        ADD         rsp,24
        POP         r15 r14 r13 r12 rbp rbx rdi rsi
        RET
;=============================================================================
; Update global state. Runs in the main thread.
align 32
update_state:
;-----------------------------------------------------------------------------
        SUB         rsp,24
        VXORPS      xmm0,xmm0,xmm0
        ;VCVTSD2SS   xmm0,xmm0,[time]
        VBROADCASTSS ymm0,xmm0
        VMULPS      ymm0,ymm0,[k_0_5]
        CALL        sincos
        VMOVAPS     ymm2,[k_camera_radius]
        VMULPS      ymm0,ymm0,ymm2
        VMULPS      ymm1,ymm1,ymm2
        VMOVSS      [eye_position+0],xmm0
        VMOVSS      [eye_position+8],xmm1
        VXORPS      xmm0,xmm0,xmm0
        VCVTSD2SS   xmm0,xmm0,[time]
        VBROADCASTSS ymm0,xmm0
        VMULPS      ymm0,ymm0,[k_0_5]
        CALL        sincos
        VMOVAPS     ymm2,[k_sphere_radius]
        VMULPS      ymm0,ymm0,ymm2
        VMULPS      ymm1,ymm1,ymm2
        VMOVSS      [object.param_x+4],xmm1
        VMOVSS      [object.param_z+4],xmm0
        VXORPS      ymm2,ymm2,ymm2
        VSUBPS      ymm0,ymm2,ymm0
        VSUBPS      ymm1,ymm2,ymm1
        VMOVSS     [object.param_x+8],xmm1
        VMOVSS     [object.param_z+8],xmm0
        VBROADCASTSS ymm0,[eye_position+0]             ; ymm0 = eye x pos
        VBROADCASTSS ymm3,[eye_focus+0]
        VBROADCASTSS ymm1,[eye_position+4]             ; ymm1 = eye y pos
        VBROADCASTSS ymm4,[eye_focus+4]
        VBROADCASTSS ymm2,[eye_position+8]             ; ymm2 = eye z pos
        VBROADCASTSS ymm5,[eye_focus+8]
        VSUBPS      ymm3,ymm0,ymm3
        VSUBPS      ymm4,ymm1,ymm4
        VSUBPS      ymm5,ymm2,ymm5
        VMULPS      ymm6,ymm3,ymm3
        VMULPS      ymm7,ymm4,ymm4
        VMULPS      ymm8,ymm5,ymm5
        VADDPS      ymm6,ymm6,ymm7
        VADDPS      ymm6,ymm6,ymm8
        VRSQRTPS    ymm6,ymm6
        VMULPS      ymm3,ymm3,ymm6
        VMULPS      ymm4,ymm4,ymm6
        VMULPS      ymm5,ymm5,ymm6                    ; (ymm3,ymm4,ymm5) = normalized(iz)
        VMOVAPS     [eye_zaxis+$000],ymm3
        VMOVAPS     [eye_zaxis+$020],ymm4
        VMOVAPS     [eye_zaxis+$040],ymm5
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
;========================================================================