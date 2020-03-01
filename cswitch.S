/*
 * Compile using:
 *   avr-gcc -c -O2 -mmcu=${CPU} -Wa,--gstabs -o switch.o switch.S
 */

/*
  * Note:
  *
  * This code is based on "thread_swtch.S" by Brian S. Dean, and the
  * "os_cpu_a.asm" of uC/OS-II AVR Specific code by Ole Saether.
  * They are adapted to match our need of a "full-served" kernel model.
  *
  *  Author:  Dr. Mantis Cheng, 28 September 2006.
  *
  *  ChangeLog: Modified by Alexander M. Hoole, October 2006.
  *
  *  !!!!!   This code has NEVER been tested.  !!!!!
  *  !!!!!   Use at your own risk  !!!!
  */


/* locations of well-known registers */
SREG  = 0x3F
SPH    = 0x3E
SPL    = 0x3D
EIND  = 0x3C

/*
  * MACROS
  */
;
; Push all registers and then the status register.
; It is important to keep the order of SAVECTX and RESTORECTX  exactly
; in reverse. Also, when a new process is created, it is important to
; initialize its "initial" context in the same order as SAVECTX.
;
.macro	SAVECTX
	push	r0
	push	r1
	push	r2
	push	r3
	push	r4
	push	r5
	push	r6
	push	r7
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	r16
	push	r17
	push	r18
	push	r19
	push	r20
	push	r21
	push	r22
	push	r23
	push	r24
	push	r25
	push	r26
	push	r27
	push	r28
	push	r29
	push	r30
	push	r31
  in  r31, EIND
  push  r31
	in	r16, SREG
	push	r16
.endm
;
; Pop all registers and the status registers
;
.macro	RESTORECTX
	pop	r16
	out	SREG,r16
	pop  r31
  out  EIND,r31
  pop	r31
	pop	r30
	pop	r29
	pop	r28
	pop	r27
	pop	r26
	pop	r25
	pop	r24
	pop	r23
	pop	r22
	pop	r21
	pop	r20
	pop	r19
	pop	r18
	pop	r17
	pop	r16
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	r7
	pop	r6
	pop	r5
	pop	r4
	pop	r3
	pop	r2
	pop	r1
	pop	r0
.endm

        .section .text
        .global CSwitch
        .global Exit_Kernel
        .global Enter_Kernel
        .extern  KernelSp
        .extern  CurrentSp
/*
  * The actual CSwitch() code begins here.
  *
  * This function is called by the kernel. Upon entry, we are using
  * the kernel stack, on top of which contains the return address
  * of the call to CSwitch() (or Exit_Kernel()).
  *
  * Assumption: Our kernel is executed with interrupts already disabled.
  *
  * Note: AVR devices use LITTLE endian format, i.e., a 16-bit value starts
  * with the lower-order byte first, then the higher-order byte.
  *
  * void CSwitch();
  * void Exit_Kernel();
  */
CSwitch:
Exit_Kernel:
        /*
          * This is the "top" half of CSwitch(), generally called by the kernel.
          * Assume I = 0, i.e., all interrupts are disabled.
          */
        SAVECTX
        /*
          * Now, we have saved the kernel's context.
          * Save the current H/W stack pointer into KernelSp.
          */
        in   r30, SPL
        in   r31, SPH
        sts  KernelSp, r30
        sts  KernelSp+1, r31
        /*
          * We are now ready to restore Cp's context, i.e.,
          * switching the H/W stack pointer to CurrentSp.
          */
        lds  r30, CurrentSp
        lds  r31, CurrentSp+1
        out  SPL, r30
        out  SPH, r31
        /*
          * We are now executing in Cp's stack.
          * Note: at the bottom of the Cp's context is its return address.
          */
        RESTORECTX
        reti         /* re-enable all global interrupts */
/*
  * All system call eventually enters here!
  * There are two possibilities how we get here:
  *  1) Cp explicitly invokes one of the kernel API call stub, which indirectly
  *       invoke Enter_Kernel().
  *  2) a timer interrupt, which somehow "jumps" into here.
  * Let us consider case (1) first. You have to figure out how to deal with
  * timer interrupts yourself.
  *
  * Assumption: All interrupts are disabled upon entering here, and
  *     we are still executing on Cp's stack. The return address of
  *     the caller of Enter_Kernel() is on the top of the stack.
  *
  * void Enter_Kernel();
  */
Enter_Kernel:
        /*
          * This is the "bottom" half of CSwitch(). We are still executing in
          * Cp's context.
          */
        SAVECTX
        /*
          * Now, we have saved the Cp's context.
          * Save the current H/W stack pointer into CurrentSp.
          */
        in   r30, SPL
        in   r31, SPH
        sts  CurrentSp, r30
        sts  CurrentSp+1, r31
        /*
          * We are now ready to restore kernel's context, i.e.,
          * switching the H/W stack pointer back to KernelSp.
          */
        lds  r30, KernelSp
        lds  r31, KernelSp+1
        out  SPL, r30
        out  SPH, r31
        /*
          * We are now executing in kernel's stack.
          */
       RESTORECTX
        /*
          * We are ready to return to the caller of CSwitch() (or Exit_Kernel()).
          * Note: We should NOT re-enable interrupts while kernel is running.
          *         Therefore, we use "ret", and not "reti".
          */
       ret
/* end of CSwitch() */
