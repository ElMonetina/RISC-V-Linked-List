.data
newline: .string "\n"
listInput: .string "ADD(1)~ADD(a)~ADD()~ADD(B)~ADD~ADD(9)~PRINT~SORT(a)~PRINT~DEL(bb)~DEL(B)~ PRINT~REV~PRINT"
#listInput: .string "ADD(1)~ADD(a)~ADD(a)~ADD(B)~ADD(;)~ADD(9)~PRINT~SORT~PRINT~DEL(b)~DEL(B)~PRI~ REV~ PRINT"
#listInput: .string "REV         ~ SORT ~ ADD(aa)~DEL(b)~ADD(4)~ADD(f)~ADD(F)~ADD(-)~ADD(4)~ADD(4)~PRINT~SORT~PRINT~DEL(4)~REV~PRINT"
lfsr: .word 372198

.text
lw s0 lfsr
li s1 0
li s2 0
la s4 listInput

add a1 s4 zero 

main: 
    j DECODING

ADD:
    jal address_generator
    bne s1 zero not_first_ADD
    add s1 a3 zero
    li t0 0xffffffff
    sw t0 0(a3)
    sw t0 5(a3)
    sb a2 4(a3)
    add s2 a3 zero
    j DECODING
    
    not_first_ADD:
        li t0 0xffffffff
        sb a2 4(a3)
        sw t0 5(a3)
        sw a3 5(s2)
        sw s2 0(a3)
        add s2 a3 zero
     j DECODING

PRINT:

    li t0 0xffffffff
    add t1 s1 zero
    beq t1 zero DECODING
    PRINT_loop:
        beq t0 t1 new_line
        lb a0 4(t1)
        li a7 11
        ecall
        lw t1 5(t1)
        j PRINT_loop
        new_line:
            la a0 newline
            li a7 4
            ecall
            j DECODING

DEL:

    li t0 0xffffffff
    add t1 s1 zero
    beq t1 zero DECODING
    DEL_loop:
        lb t2 4(t1)
        beq a2 t2 delete_element
        lw t1 5(t1)
        beq t1 t0 DECODING
        j DEL_loop

    delete_element:
        lw t4 0(t1)
        lw t5 5(t1)
        beq t0 t4 del_first_element
        beq t0 t5 del_last_element
        sw t5 5(t4)
        sw t4 0(t5)
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        j DECODING

    del_first_element:
        beq t0 t5 del_only_element
        sw t0 0(t5)

        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        add s1 t5 zero
        j DECODING 

    del_only_element:
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        add s1 zero zero
        j DECODING

    del_last_element:
        sw t0 5(t4)
        sw zero 0(t1)
        sb zero 4(t1)
        sw zero 5(t1)
        add s2 t4 zero
        j DECODING

SORT:
    beq s1 zero DECODING
    add t1 s1 zero
    li t0 0

    SORT_loop:
        lb a4 4(t1)
        lw t3 5(t1)
        lb a5 4(t3)
        li t5 0xffffffff
        beq t3 t5 check_swapped
        jal swap_check
        bne a2 zero swap_element
        add t1 t3 zero
        j SORT_loop

    swap_element:
        sb a4 4(t3)
        sb a5 4(t1)
        li t0 1
        add t1 t3 zero
        j SORT_loop
    check_swapped:
        beq t0 zero DECODING
        j SORT

REV:
    li t0 0xffffffff
    beq s1 zero DECODING
    add t1 s1 zero
    REV_loop:
        lw t4 0(t1)
        lw t5 5(t1)
        add t3 t5 zero 
        sw t4 5(t1)
        sw t5 0(t1)
        beq t1 t0 head_rear_swap
        add t1 t3 zero
        j REV_loop
        
    head_rear_swap:
        add t2 s2 zero
        add s2 s1 zero
        add s1 t2 zero
        j DECODING
         
address_generator:

    srli t0 s0 0
    srli t1 s0 2
    srli t2 s0 3
    srli t3 s0 5

    xor t0 t0 t1
    xor t0 t0 t2
    xor t0 t0 t3

    srli t1 s0 1
    slli t0 t0 15
    or t1 t1 t0
 
    li t4 0x0000ffff
    and t1 t1 t4
    li t4 0x00010000
    or a3 t1 t4
    add s0 a3 zero

    add t0 a3 zero
    lw t1 0(t0)
    bne t1 zero address_generator
    lb t1 4(t0)
    bne t1 zero address_generator
    lw t1 5(t0)
    bne t1 zero address_generator
    jr ra

swap_check:

    check_first:
        li t2 65
        blt a4 t2 check_number_first
        li t2 90
        bgt a4 t2 check_minuscola_first
        li t4 4
        j check_second

    check_minuscola_first:
        li t2 97
        blt a4 t2 set_special_char_first
        li t2 122
        bgt a4 t2 set_special_char_first
        li t4 3
        j check_second

    check_number_first:
        li t2 48
        blt a4 t2 set_special_char_first
        li t2 57
        bgt a4 t2 set_special_char_first
         li t4 2
        j check_second
    set_special_char_first:
        li t4 1

    check_second:
        li t2 65
        blt a5 t2 check_number_second
        li t2 90
        bgt a5 t2 check_minuscola_second
        li t6 4
        j check_priority
    check_minuscola_second:
        li t2 97
        blt a5 t2 set_special_char_second
        li t2 122
        bgt a5 t2 set_special_char_second
        li t6 3
        j check_priority
    check_number_second:
        li t2 48
        blt a5 t2 set_special_char_second
        li t2 57
        bgt a5 t2 set_special_char_second
        li t6 2
        j check_priority
    set_special_char_second:
        li t6 1
    check_priority:
        li a2 0
        bgt t4 t6 set_swapper
        beq t4 t6 check_elements
        jr ra

    check_elements:
        bgt a4 a5 set_swapper
        jr ra
    set_swapper:
        li a2 1
        jr ra

DECODING:

    check_initial_spaces:
        lb t1 0(a1)
        li t2 32
        bne t1 t2 CHECK_ADD
        addi a1 a1 1
        j check_initial_spaces

    CHECK_ADD:
        
        check_A:
            lb t1 0(a1)
            li t2 65
            beq t1 t2 check_D1
            j CHECK_PRINT
        check_D1:
            addi a1 a1 1
            lb t1 0(a1)
            li t2 68
            beq t1 t2 check_D2
            j check_next_instruction
        check_D2:
            addi a1 a1 1
            lb t1 0(a1)
            li t2 68
            beq t1 t2 check_value_ADD
            j check_next_instruction

        check_value_ADD: 
             addi a1 a1 1
             lb t1 0(a1)
             li t2 40
             bne t1 t2 check_next_instruction
             addi a1 a1 1
             lb a2 0(a1)
             li t2 32
             blt a2 t2 check_next_instruction
             li t2 125
             bgt a2 t2 check_next_instruction
             addi a1 a1 1
             lb t1 0(a1)
             li t2 41
             bne t1 t2 check_next_instruction

        check_correct_format_ADD:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 32
             bne t1 t2 check_next_tilde
             j check_correct_format_ADD
             check_next_tilde:
                 lb t1 0(a1)
                 li t2 126
                 beq t1 t2 ADD
                 lb t1 0(a1)
                 li t2 0
                 bne t1 t2 check_next_instruction
                 j ADD
                 
     CHECK_PRINT:
         
         check_P:
             lb t1 0(a1)
             li t2 80
             beq t1 t2 check_R1
             j CHECK_DEL   
         check_R1:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 82
             beq t1 t2 check_I
             j check_next_instruction
         check_I:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 73
             beq t1 t2 check_N
             j check_next_instruction
         check_N:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 78
             beq t1 t2 check_T1
             j check_next_instruction             
         check_T1:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 84
             bne t1 t2 check_next_instruction
             check_correct_format_PRINT:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32
                 bne t1 t2 check_tilde_PRINT
                 j check_correct_format_PRINT
                 check_tilde_PRINT:
                     lb t1 0(a1)
                     li t2 126
                     beq t1 t2 PRINT
                     lb t1 0(a1)
                     li t2 0
                     bne t1 t2 check_next_instruction
                     j PRINT
                     
     CHECK_DEL:
         
         check_D3:
             lb t1 0(a1)
             li t2 68
             beq t1 t2 check_E1
             j CHECK_SORT             
         check_E1:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 69
             beq t1 t2 check_L
             j check_next_instruction             
         check_L:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 76
             beq t1 t2 check_value_DEL
             j check_next_instruction
         check_value_DEL:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 40
             bne t1 t2 check_next_instruction
             addi a1 a1 1
             lb a2 0(a1)
             addi a1 a1 1
             lb t1 0(a1)
             li t2 41
             bne t1 t2 check_next_instruction
             check_correct_format_DEL:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32
                 bne t1 t2 check_tilde_DEL
                 j check_correct_format_DEL
                 check_tilde_DEL:
                     lb t1 0(a1)
                     li t2 126
                     beq t1 t2 DEL
                     lb t1 0(a1)
                     li t2 0
                     bne t1 t2 check_next_instruction
                     j DEL
                   
     CHECK_SORT:
         
         check_S:
             lb t1 0(a1)
             li t2 83
             beq t1 t2 check_O
             j CHECK_REV
         check_O:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 79
             beq t1 t2 check_R2
             j check_next_instruction
         check_R2:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 82
             beq t1 t2 check_T2
             j check_next_instruction
         check_T2:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 84
             bne t1 t2 check_next_instruction
             check_correct_format_SORT:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32
                 bne t1 t2 check_tilde_SORT
                 j check_correct_format_SORT
                 check_tilde_SORT:
                     lb t1 0(a1)
                     li t2 126
                     beq t1 t2 SORT
                     lb t1 0(a1)
                     li t2 0
                     bne t1 t2 check_next_instruction
                     j SORT
     
     CHECK_REV:
         
         check_R3:
             lb t1 0(a1)
             li t2 82
             beq t1 t2 check_E2
             j check_next_instruction             
         check_E2:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 69
             beq t1 t2 check_V
             j check_next_instruction
         check_V:
             addi a1 a1 1
             lb t1 0(a1)
             li t2 86
             bne t1 t2 check_next_instruction
             check_correct_format_REV:
                 addi a1 a1 1
                 lb t1 0(a1)
                 li t2 32
                 bne t1 t2 check_tilde_REV
                 j check_correct_format_REV
                 check_tilde_REV:
                     lb t1 0(a1)
                     li t2 126
                     beq t1 t2 REV
                     lb t1 0(a1)
                     li t2 0
                     bne t1 t2 check_next_instruction
                     j REV

     check_next_instruction:

         check_spaces:
             lb t1 0(a1)
             li t2 32
             bne t1 t2 check_tilde
             addi a1 a1 1
             j check_spaces

         check_tilde:
             lb t1 0(a1)
             li t2 126
             beq t1 t2 next
             addi a1 a1 1
             lb t1 0(a1)
             li t3 0
             beq t1 t3 exit
             j check_tilde
         next:
             addi a1 a1 1
             j DECODING

exit:
li a7 10
ecall