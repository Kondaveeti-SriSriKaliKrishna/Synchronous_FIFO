// Synchronous FIFO 

module fifo_sync #(
    parameter DEPTH = 16,
    parameter WIDTH = 8,
    parameter ALMOST_FULL_THRESH = 12,
    parameter ALMOST_EMPTY_THRESH = 4,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input clk,
    input rst,
    input [WIDTH-1:0] wdata,
    output reg [WIDTH-1:0] rdata,
    input wr_valid,
    input rd_valid,
    
    // Status Flags
    output fifo_full,
    output fifo_empty,
    output fifo_almost_full,
    output fifo_almost_empty,
    output [PTR_WIDTH:0] fifo_count,
    
    // Error Flags
    output wr_error,
    output rd_error
);

    // Memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTR_WIDTH:0] wr_ptr, rd_ptr;

    // Full Detection
    assign fifo_full = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) &&
                       (wr_ptr[PTR_WIDTH]     != rd_ptr[PTR_WIDTH]);
    // Empty Detection
    assign fifo_empty = (wr_ptr == rd_ptr);

    // Occupancy & Threshold Flags
    assign fifo_count = wr_ptr - rd_ptr;
    assign fifo_almost_full = (fifo_count >= ALMOST_FULL_THRESH);
    assign fifo_almost_empty = (fifo_count <= ALMOST_EMPTY_THRESH);

    // Errors
    assign wr_error = fifo_full && wr_valid;
    assign rd_error = fifo_empty && rd_valid;

    // Read/Write Logic
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            rdata <= '0;
        end else begin
            if (wr_valid && !fifo_full) begin
                mem[wr_ptr[PTR_WIDTH-1:0]] <= wdata;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (rd_valid && !fifo_empty) begin
                rdata <= mem[rd_ptr[PTR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
