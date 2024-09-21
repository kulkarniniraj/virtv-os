ENTRY( _entry )
SECTIONS
{
    /*
    * ensure that entry.S / _entry is at 0x80000000,
    * where qemu's -kernel jumps.
    */
    . = 0x80000000;

    .text : {
        *(.text)        
    }
    .rodata : ALIGN(4K) {
		*(.rodata);
	}
	.data : ALIGN(4K) {
		*(.data);
        *(.sdata);
	}
}