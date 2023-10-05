.option norvc
.section .data

.section .text.init
.global _start
_start:
  // Get the ID of the currently running hart.
  csrr t0, mhartid
  // If the hart ID is not 0, then just make the hart spin as we only need one
  // hart to execute the boot code.
  bnez  t0, 3f
  // Clear the SATP CSR as we want to work with physical addresses and while booting
  // do not want virtual memory enabled.
  csrw satp, zero
.option push
.option norelax
  la gp, _global_pointer
.option pop
  la a0, _bss_start
  la a1, _bss_end
  // Skip clearing the BSS section if the address of _bss_start is greater than
  // the address of _bss_end.
  bgeu a0, a1, 2f

1:
  // Clear the BSS section, where a0 is initially the address of _bss_start.
#if __riscv_xlen == 64
  sd zero, (a0)
#elif __riscv_xlen == 32
  sw zero, (a0)
#endif
  addi a0, a0, 8
  bltu a0, a1, 1b

2:
  // Load the end of the stack into the stack pointer before we jump to kmain.
  la sp, _stack
  // Here we set the mstatus CSR with the following bits:
  // MIE (bit 3) is set to globally enable interrupts
  // MPIE (bit 7) holds the value of the interrupt-enable bit active prior to the trap,
  // since we keep interrupts on, this stays set.
  // MPP (bits 11 and 12) are set to the privilege level we want to return to
  // when we execute the mret instruction, in this case we set it to 0b11
  // since we want to stay in machine mode (M-mode).
  li t0, (0b11 << 11) | (1 << 7) | (1 << 3)
  csrw mstatus, t0
  // Set the address of kmain function in our Zig code to be the program
  // counter when we return (aka when we execute the mret instruction)
  la t1, kmain
  csrw mepc, t1
  // Set the address of the trap function in our Zig code to be the trap-handler
  // It will get invoked whenever we get an exception, for example an interrupt
  la t2, trap
  csrw mtvec, t2
  // Set the M-mode interrupt enable bits
  // MSIE (bit 3) is set for software interrupts such as IPIs
  // (inter-processer interrupts), which will become relevant when using other
  // harts.
  // MEIE (bit 11) is set to enable external interrupts from hardware devices
  // such as an ethernet device or serial UART device.
  // Note that MTIE is *not* set as the kernel does not handle timer-interrupts
  // and we want to prevent the situation where the trap entry-point is invoked
  // before we even get to the kmain entry-point.
  li t3, (1 << 3) | (1 << 11)
  csrw mie, t3
  // Finally, we have the return address (ra) to
  la ra, 4f
  mret

3:
4:
  // Spin the hart
  wfi
  j 4b
