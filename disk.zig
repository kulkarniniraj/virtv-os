const stdio = @import("stdio.zig");
const utils = @import("utils.zig");

const VIRTIO_MMIO_BASE = 0x10001000;

const MAGIC_VALUE_REG = 0x0;
const VERSION_REG = 0x4;
const DEVICE_ID_REG = 0x8;
const VENDOR_ID_REG = 0xc;

const DEVICE_FEATURE_REG = 0x10;
const DRIVER_FEATURE_REG = 0x20;

const QUEUESEL_REG = 0x30;
const QUEUESIZE_MAX_REG = 0x34;
const QUEUESIZE_REG = 0x38;
const QUEUEREADY_REG = 0x44;
const QUEUENOTIFY_REG = 0x50;
const INTR_STATUS_REG = 0x60;

const STATUS_REG = 0x70;

const QUEUEDESC_REG = 0x80;
const QUEUEDRIVER_REG = 0x90;
const QUEUEDEVICE_REG = 0xA0;

const CONFIG_REG = 0x100;

const Virtio_Blk_Config = packed struct {
    capacity: u64,
    extra1: u64,
    extra2: u32,        //geometry    
    blk_size: u32,     
    extra3: u64,        // topology
    extra4: u16,        // writeback + unused0
    num_queues: u16, 
        
    extra5: u96,     // discard attrs
    extra6: u72,      // zeroes attrs
    unused1: u24,
    
    extra7: u96,     // erase attrs
    extra8: u176,     // zone attrs
};

const VirtQ_Desc = packed struct {
    addr: u64,
    len: u32,
    flags: u16,
    next: u16
};

const VirtQ_Avail = extern struct {
    flags: u16,
    idx: u16,
    ring: [MAX_QUEUE_SIZE]u16,
    unused: u16
};

const VirtQ_Used = extern struct {
    flags: u16,
    idx: u16,
    used_elem_array: [MAX_QUEUE_SIZE] VirtQ_Used_Elem,
};

const VirtQ_Used_Elem = packed struct {
    id: u32,
    len: u32
};

const Virtio_Blk_Request = packed struct {
    rtype: u32,
    reserved: u32,
    sector: u64,
};

// virtio_blk_req

// : [MAX_QUEUE_SIZE]VirtQ_Desc
var virtq_desc_array align(16) = [_]VirtQ_Desc{
    .{.addr = 0, .len = 0, .flags = 0, .next = 0}}**8;

var virtq_avail: VirtQ_Avail align(2) = .{.flags = 0, .idx = 0, 
    .ring = .{0} ** MAX_QUEUE_SIZE, .unused = 0};

var virtq_used: VirtQ_Used align(4) = .{
    .flags = 0, .idx = 0, 
    .used_elem_array = [_]VirtQ_Used_Elem{.{.id = 0, .len = 0}} ** MAX_QUEUE_SIZE};

// : [MAX_QUEUE_SIZE]Virtio_Blk_Request
var virtio_blk_request_array = 
    [_]Virtio_Blk_Request{.{.rtype = 0, .reserved = 0, .sector = 0}} ** MAX_QUEUE_SIZE;

const MAGIC_VALUE = 0x74726976;
const VENDOR_ID = 0x554d4551;
const STATUS = enum(u32){
    RESET = 0,
    ACK = 1,
    DRIVER = 2,
    FEATURE_OK = 8,
    DRIVER_OK = 4,
    NEED_RESET = 64,
    FAILED = 128
};

const VIRTIO_BLK_T_IN: u32 = 0;
const VIRTIO_BLK_T_OUT: u32 = 1;

const MAX_QUEUE_SIZE = 8;

const VRING_DESC_F_NEXT: u32 = 1;
const VRING_DESC_F_WRITE: u32 =  2;

var read_buffer: [512]u8 = undefined;
var blk_op_status: u8 = 0xff;


fn get_register(offset: u32) u32 {
    const mmio: *u32 = @ptrFromInt(VIRTIO_MMIO_BASE + offset);
    return mmio.*;
}

fn set_register(offset: u32, val: u32) void {
    const mmio: *u32 = @ptrFromInt(VIRTIO_MMIO_BASE + offset);
    mmio.* = val;
}

pub fn init() void {
    var status: u32 = 0;
 
    stdio.print("mmio magic val: ");
    stdio.printUIntHex(get_register(MAGIC_VALUE_REG));
    stdio.print("\n");

    stdio.print("mmio version: ");
    stdio.printUIntHex(get_register(VERSION_REG));
    stdio.print("\n");

    stdio.print("mmio device id: ");
    stdio.printUIntHex(get_register(DEVICE_ID_REG));
    stdio.print("\n");   

    status = @intFromEnum(STATUS.RESET);
    set_register(STATUS_REG, status);

    status |= @intFromEnum(STATUS.ACK);
    set_register(STATUS_REG, status);

    status |= @intFromEnum(STATUS.DRIVER);
    set_register(STATUS_REG, status);

    stdio.print("feawtures bits: ");
    stdio.printUIntHex(get_register(DEVICE_FEATURE_REG));
    stdio.print("\n");

    negotiate_features();

    const config: *Virtio_Blk_Config = @ptrFromInt(VIRTIO_MMIO_BASE + CONFIG_REG);
    stdio.print("capacity: "); stdio.printUIntHex(config.capacity); stdio.print("\n");

    stdio.print("queues: "); stdio.printUIntHex(config.num_queues); stdio.print("\n");

    set_register(QUEUESEL_REG, 0);
    
    stdio.print("max queue size: "); 
    stdio.printUIntHex(get_register(QUEUESIZE_MAX_REG)); 
    stdio.print("\n");

    set_register(QUEUESIZE_REG, MAX_QUEUE_SIZE);

    const qdesc: *u64 = @ptrFromInt(VIRTIO_MMIO_BASE + QUEUEDESC_REG);
    qdesc.* = @intFromPtr(&virtq_desc_array);

    const qdriver: *u64 = @ptrFromInt(VIRTIO_MMIO_BASE + QUEUEDRIVER_REG);
    qdriver.* = @intFromPtr(&virtq_avail);

    const qdevice: *u64 = @ptrFromInt(VIRTIO_MMIO_BASE + QUEUEDEVICE_REG);
    qdevice.* = @intFromPtr(&virtq_used);

    set_register(QUEUEREADY_REG, 1);

    set_register(STATUS_REG, get_register(STATUS_REG) | @intFromEnum(STATUS.DRIVER_OK));

    stdio.print("final status: "); 
    stdio.printUIntHex(get_register(STATUS_REG)); 
    stdio.print("\n");

}

pub fn read_block() void {
    virtio_blk_request_array[0].rtype = VIRTIO_BLK_T_IN;
    virtio_blk_request_array[0].sector = 0;

    virtq_desc_array[0].addr = @intFromPtr(&virtio_blk_request_array[0]);
    virtq_desc_array[0].len = @sizeOf(Virtio_Blk_Request);
    virtq_desc_array[0].flags = VRING_DESC_F_NEXT;
    virtq_desc_array[0].next = 1;

    virtq_desc_array[1].addr = @intFromPtr(&read_buffer);
    virtq_desc_array[1].len = 512;
    virtq_desc_array[1].flags = VRING_DESC_F_NEXT | VRING_DESC_F_WRITE;
    virtq_desc_array[1].next = 2;

    virtq_desc_array[2].addr = @intFromPtr(&blk_op_status);
    virtq_desc_array[2].len = 1;
    virtq_desc_array[2].flags = VRING_DESC_F_WRITE;
    virtq_desc_array[2].next = 0;

    virtq_avail.idx = 0;
    virtq_avail.ring[0] = 0;
    virtq_avail.idx = 1;

    utils.delay(10);

    set_register(QUEUENOTIFY_REG, 0);
}

pub fn check_status() void {
    while(true){
        stdio.print("disk intr status: "); 
        stdio.printUIntHex(get_register(INTR_STATUS_REG)); 
        stdio.print("\n");   

        if(get_register(INTR_STATUS_REG) == 1) {
            stdio.print("disk content: ");
            stdio.print(read_buffer[0..30]);
            stdio.print("\n");
            break;
        }

        stdio.print("disk op status: "); 
        stdio.printUIntHex(blk_op_status); 
        stdio.print("\n");    

        stdio.print("virtio status: "); 
        stdio.printUIntHex(get_register(STATUS_REG)); 
        stdio.print("\n");    
        utils.delay(50);
    }
    
}

fn negotiate_features() void {
    // var ftrs = get_register(DEVICE_FEATURE_REG);
    set_register(DRIVER_FEATURE_REG, 0x0);
    set_register(STATUS_REG, get_register(STATUS_REG) | @intFromEnum(STATUS.FEATURE_OK));

    if(get_register(STATUS_REG) & @intFromEnum(STATUS.FEATURE_OK) != 0){
        stdio.print("negtiation complete\n");
    }
    else {
        stdio.print("negtiation failed\n");
    }
}