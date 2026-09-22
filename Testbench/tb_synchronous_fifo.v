`timescale 1ns/1ps
`include "synchronous_fifo.v"

module tb;

    parameter DEPTH = 16;
    parameter WIDTH = 8;
    parameter ALMOST_FULL_THRESH  = 12;
    parameter ALMOST_EMPTY_THRESH = 4;
    parameter PTR_WIDTH = $clog2(DEPTH);
	parameter TP = 10;

    reg clk, rst;

    reg  [WIDTH-1:0] wdata;
    wire [WIDTH-1:0] rdata;

    reg wr_valid, rd_valid;

    wire fifo_full, fifo_empty;
    wire fifo_almost_full, fifo_almost_empty;

    wire [PTR_WIDTH:0] fifo_count;

    wire wr_error, rd_error;

    integer i, j;

    reg [8*30:1] testname;

    fifo_sync #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH),
        .ALMOST_FULL_THRESH(ALMOST_FULL_THRESH),
        .ALMOST_EMPTY_THRESH(ALMOST_EMPTY_THRESH),
        .PTR_WIDTH(PTR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wdata(wdata),
        .rdata(rdata),
        .wr_valid(wr_valid),
        .rd_valid(rd_valid),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_almost_full(fifo_almost_full),
        .fifo_almost_empty(fifo_almost_empty),
        .fifo_count(fifo_count),
        .wr_error(wr_error),
        .rd_error(rd_error)
    );

  	always #(TP/2) clk = ~clk; // clk generator

    initial begin

        $value$plusargs("testname=%s", testname);
		clk = 0;
        rst = 0;
        wr_valid = 0;
        rd_valid = 0;
        wdata  = 0;

        reset_fifo();

        case(testname)

            "test_full": begin
                write_fifo(DEPTH);
            end

            "test_empty": begin
                write_fifo(DEPTH);
                read_fifo(DEPTH);
            end

            "test_overflow": begin
                write_fifo(DEPTH);

                @(negedge clk);
                wr_valid = 1;
                wdata  = 8'hFF;

                @(posedge clk);
                #1;

                $display("wr_error = %b", wr_error);

                @(negedge clk);
                wr_valid = 0;
                wdata  = 0;
            end

            "test_underflow": begin
                write_fifo(DEPTH);
                read_fifo(DEPTH);

                @(negedge clk);
                rd_valid = 1;

                @(posedge clk);
                #1;

                $display("rd_error = %b", rd_error);

                @(negedge clk);
                rd_valid = 0;
            end

            "test_concurrent_wr_rd": begin
                write_fifo(DEPTH/2);
                fork
                    write_fifo(DEPTH/2);
                    read_fifo(DEPTH/2);
                join
            end
        endcase
        #20;
        $finish;
    end

	// RESET FIFO 
    task reset_fifo;
        begin
            rst = 1;
                @(negedge clk);
            rst = 0;
            @(negedge clk);
        end
    endtask

	// WRITE FIFO TASK
    task write_fifo;
        input integer num_writes;
        begin
            for(i = 0; i < num_writes; i = i + 1) begin
                @(negedge clk);
                wr_valid = 1;
                wdata  = $random;
                @(posedge clk);
                #1;
                $display(
    			   "time=%0t WRITE[%0d] : data=%0d, count=%0d, full=%b, almost_full=%b",
                    $time,
                    i,
                    wdata,
                    fifo_count,
                    fifo_full,
					fifo_almost_full
                );
            end
            @(negedge clk);
            wr_valid = 0;
            wdata  = 0;
        end
    endtask

	// READ FIFO TASK
    task read_fifo;
        input integer num_reads;
        begin
            for(j = 0; j < num_reads; j = j + 1) begin
                @(negedge clk);
                rd_valid = 1;
                @(posedge clk);
                #1;
                $display(
				   "time=%0t READ[%0d] : data=%0d, count=%0d, empty=%b, almost_empty=%b",
                    $time,
                    j,
                    rdata,
                    fifo_count,
                    fifo_empty,
					fifo_almost_empty
                );
            end
            @(negedge clk);
            rd_valid = 0;
        end
    endtask
endmodule
