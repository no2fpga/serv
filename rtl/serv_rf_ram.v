module serv_rf_ram
  #(parameter width=0,
    parameter csr_regs=0,
    parameter depth=32*(32+csr_regs)/width)
   (input wire i_clk,
    input wire [1:0]               i_bank,
    input wire [$clog2(depth)-1:0] i_waddr,
    input wire [width-1:0]         i_wdata,
    input wire                     i_wen,
    input wire [$clog2(depth)-1:0] i_raddr,
    output reg [width-1:0]         o_rdata);

   localparam mem_depth = 4096 / width;
   localparam mem_aw    = $clog2(mem_depth);
   localparam ext_aw    = $clog2(depth);

   reg  [width -1:0] memory [0:mem_depth-1];
   wire [mem_aw-1:0] m_waddr;
   wire [mem_aw-1:0] m_raddr;

   generate
     if (csr_regs > 0) begin
       assign m_waddr = 0;  // FIXME
       assign m_raddr = 0;  // FIXME
     end else begin
       assign m_waddr = |i_waddr[ext_aw-1:ext_aw-2] ? { i_bank, i_waddr } : { 2'b00, i_waddr };
       assign m_raddr = |i_raddr[ext_aw-1:ext_aw-2] ? { i_bank, i_raddr } : { 2'b00, i_raddr };
     end
   endgenerate

   always @(posedge i_clk) begin
      if (i_wen)
        memory[m_waddr] <= i_wdata;
      o_rdata <= memory[m_raddr];
   end

`ifdef SERV_CLEAR_RAM
   integer i;
   initial
     for (i=0;i<depth;i=i+1)
       memory[i] = {width{1'd0}};
`endif

`ifdef SERV_INIT_RAM
   initial
     $readmemh(`SERV_INIT_RAM, memory);
`endif

endmodule
