`default_nettype none

module serv_rf_top
  #(parameter RESET_PC = 32'd0,

    /* Amount of reset applied to design
       "NONE" : No reset at all. Relies on a POR to set correct initialization
                 values and that core isn't reset during runtime
       "MINI" : Standard setting. Resets the minimal amount of FFs needed to
                 restart execution from the instruction at RESET_PC
     */
    parameter RESET_STRATEGY = "MINI",
    parameter WITH_CSR = 1,
    parameter RF_WIDTH = 2,
        parameter RF_L2D   = $clog2((32+(WITH_CSR*4))*32/RF_WIDTH))
  (
   input wire         clk,
   input wire         i_rst,
   input wire         i_timer_irq,
`ifdef RISCV_FORMAL
   output wire        rvfi_valid,
   output wire [63:0] rvfi_order,
   output wire [31:0] rvfi_insn,
   output wire        rvfi_trap,
   output wire        rvfi_halt,
   output wire        rvfi_intr,
   output wire [1:0]  rvfi_mode,
   output wire [1:0]  rvfi_ixl,
   output wire [4:0]  rvfi_rs1_addr,
   output wire [4:0]  rvfi_rs2_addr,
   output wire [31:0] rvfi_rs1_rdata,
   output wire [31:0] rvfi_rs2_rdata,
   output wire [4:0]  rvfi_rd_addr,
   output wire [31:0] rvfi_rd_wdata,
   output wire [31:0] rvfi_pc_rdata,
   output wire [31:0] rvfi_pc_wdata,
   output wire [31:0] rvfi_mem_addr,
   output wire [3:0]  rvfi_mem_rmask,
   output wire [3:0]  rvfi_mem_wmask,
   output wire [31:0] rvfi_mem_rdata,
   output wire [31:0] rvfi_mem_wdata,
`endif
   output wire [31:0] o_ibus_adr,
   output wire        o_ibus_cyc,
   input wire [31:0]  i_ibus_rdt,
   input wire         i_ibus_ack,
   output wire [31:0] o_dbus_adr,
   output wire [31:0] o_dbus_dat,
   output wire [3:0]  o_dbus_sel,
   output wire        o_dbus_we ,
   output wire        o_dbus_cyc,
   input wire [31:0]  i_dbus_rdt,
   input wire         i_dbus_ack);

   localparam CSR_REGS = WITH_CSR*4;

   wire               rf_wreq;
   wire               rf_rreq;
   wire [4+WITH_CSR:0] wreg0;
   wire [4+WITH_CSR:0] wreg1;
   wire               wen0;
   wire               wen1;
   wire               wdata0;
   wire               wdata1;
   wire [4+WITH_CSR:0] rreg0;
   wire [4+WITH_CSR:0] rreg1;
   wire               rf_ready;
   wire               rdata0;
   wire               rdata1;

   reg  [1:0]          bank;
   wire [RF_L2D-1:0]   waddr;
   wire [RF_WIDTH-1:0] wdata;
   wire                wen;
   wire [RF_L2D-1:0]   raddr;
   wire [RF_WIDTH-1:0] rdata;

   reg [RF_L2D-1:0]   waddr_r;
   reg [RF_WIDTH-1:0] wdata_r;
   reg                wen_r;

   always @(posedge clk) begin
      waddr_r <= waddr;
      wdata_r <= wdata;
      wen_r   <= wen;
   end

   serv_rf_ram_if
     #(.width    (RF_WIDTH),
       .reset_strategy (RESET_STRATEGY),
       .csr_regs (CSR_REGS))
   rf_ram_if
     (.i_clk    (clk),
      .i_rst    (i_rst),
      .i_wreq   (rf_wreq),
      .i_rreq   (rf_rreq),
      .o_ready  (rf_ready),
      .i_wreg0  (wreg0),
      .i_wreg1  (wreg1),
      .i_wen0   (wen0),
      .i_wen1   (wen1),
      .i_wdata0 (wdata0),
      .i_wdata1 (wdata1),
      .i_rreg0  (rreg0),
      .i_rreg1  (rreg1),
      .o_rdata0 (rdata0),
      .o_rdata1 (rdata1),
      .o_waddr  (waddr),
      .o_wdata  (wdata),
      .o_wen    (wen),
      .o_raddr  (raddr),
      .i_rdata  (rdata));

   always @(posedge clk)
       if (i_rst)
           bank <= 2'b00;
       else if (i_ibus_ack)
           bank <= o_ibus_adr[31:30];

   serv_rf_ram
     #(.width (RF_WIDTH),
       .csr_regs (CSR_REGS))
   rf_ram
     (.i_clk   (clk),
      .i_bank  (bank),
      .i_waddr (waddr_r),
      .i_wdata (wdata_r),
      .i_wen   (wen_r),
      .i_raddr (raddr),
      .o_rdata (rdata));

   serv_top
     #(.RESET_PC (RESET_PC),
       .RESET_STRATEGY (RESET_STRATEGY),
       .WITH_CSR (WITH_CSR))
   cpu
     (
      .clk      (clk),
      .i_rst    (i_rst),
      .i_timer_irq  (i_timer_irq),
`ifdef RISCV_FORMAL
      .rvfi_valid     (rvfi_valid    ),
      .rvfi_order     (rvfi_order    ),
      .rvfi_insn      (rvfi_insn     ),
      .rvfi_trap      (rvfi_trap     ),
      .rvfi_halt      (rvfi_halt     ),
      .rvfi_intr      (rvfi_intr     ),
      .rvfi_mode      (rvfi_mode     ),
      .rvfi_ixl       (rvfi_ixl      ),
      .rvfi_rs1_addr  (rvfi_rs1_addr ),
      .rvfi_rs2_addr  (rvfi_rs2_addr ),
      .rvfi_rs1_rdata (rvfi_rs1_rdata),
      .rvfi_rs2_rdata (rvfi_rs2_rdata),
      .rvfi_rd_addr   (rvfi_rd_addr  ),
      .rvfi_rd_wdata  (rvfi_rd_wdata ),
      .rvfi_pc_rdata  (rvfi_pc_rdata ),
      .rvfi_pc_wdata  (rvfi_pc_wdata ),
      .rvfi_mem_addr  (rvfi_mem_addr ),
      .rvfi_mem_rmask (rvfi_mem_rmask),
      .rvfi_mem_wmask (rvfi_mem_wmask),
      .rvfi_mem_rdata (rvfi_mem_rdata),
      .rvfi_mem_wdata (rvfi_mem_wdata),
`endif
      .o_rf_rreq   (rf_rreq),
      .o_rf_wreq   (rf_wreq),
      .i_rf_ready  (rf_ready),
      .o_wreg0     (wreg0),
      .o_wreg1     (wreg1),
      .o_wen0      (wen0),
      .o_wen1      (wen1),
      .o_wdata0    (wdata0),
      .o_wdata1    (wdata1),
      .o_rreg0     (rreg0),
      .o_rreg1     (rreg1),
      .i_rdata0    (rdata0),
      .i_rdata1    (rdata1),

      .o_ibus_adr   (o_ibus_adr),
      .o_ibus_cyc   (o_ibus_cyc),
      .i_ibus_rdt   (i_ibus_rdt),
      .i_ibus_ack   (i_ibus_ack),

      .o_dbus_adr   (o_dbus_adr),
      .o_dbus_dat   (o_dbus_dat),
      .o_dbus_sel   (o_dbus_sel),
      .o_dbus_we    (o_dbus_we),
      .o_dbus_cyc   (o_dbus_cyc),
      .i_dbus_rdt   (i_dbus_rdt),
      .i_dbus_ack   (i_dbus_ack));

endmodule
`default_nettype wire
