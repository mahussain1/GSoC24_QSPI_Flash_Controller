`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2024 04:09:02 PM
// Design Name: 
// Module Name: qspi_spi_controller_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//ALL THREE MODES ARE WORKING with CPOL CPHA
module qspi_spi_controller_tb;

    // Parameters
    parameter DATA_WIDTH = 4;
    parameter ADDRESS_WIDTH = 32;
    parameter COMMAND_WIDTH = 8;
//    parameter MODE = "QSPI";  // Default mode active
    parameter MODE = "SPI";  // Uncomment to test SPI mode
//    parameter MODE = "DPI";  // Uncomment to test DPI mode

    // Clock and reset
    reg clk;
    reg reset_n;

    // Inputs
    reg [DATA_WIDTH-1:0] data_in;
    reg [COMMAND_WIDTH-1:0] command;
    reg [ADDRESS_WIDTH-1:0] address;
    reg start;
    reg [1:0] CPOL;  // Clock Polarity
    reg [1:0] CPHA;  // Clock Phase

    // Outputs
    wire [DATA_WIDTH-1:0] data_out;
    wire busy;
    wire done;
    wire [DATA_WIDTH-1:0] io_lines;

    // Instantiate the Unit Under Test (UUT)
    qspi_spi_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .COMMAND_WIDTH(COMMAND_WIDTH),
        .MODE(MODE)
    ) uut (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),
        .data_out(data_out),
        .command(command),
        .address(address),
        .start(start),
        .busy(busy),
        .done(done),
        .io_lines(io_lines),
        .CPOL(CPOL),
        .CPHA(CPHA)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        reset_n = 0;
        start = 0;
        data_in = 0;
        command = 0;
        address = 0;
        CPOL = 2'b00;  // Default CPOL
        CPHA = 2'b00;  // Default CPHA

        // Apply reset
        #10;
        reset_n = 1;

        // Check the mode and apply the appropriate test case
        case (MODE)
            "QSPI": begin
                // Test case 1: QSPI Mode
                #10;
                command = 8'hA5; // Example command for QSPI
                address = 32'h12345678; // Example address for QSPI
                data_in = 4'hF; // Example data for QSPI

                // Test all CPOL and CPHA combinations
                test_modes();

            end

            "SPI": begin
                // Test case 2: SPI Mode
                #10;
                command = 8'h5A; // Example command for SPI
                address = 32'hA0A0A0A0; // Example address for SPI
                data_in = 4'h3; // Example data for SPI

                // Test all CPOL and CPHA combinations
                test_modes();

            end

            "DPI": begin
                // Test case 3: Dual SPI (DPI) Mode
                #10;
                command = 8'hF0; // Example command for DPI
                address = 32'h9B9B9B9B; // Example address for DPI
                data_in = 4'h7; // Example data for DPI

                // Test all CPOL and CPHA combinations
                test_modes();

            end

            default: begin
                $display("Invalid mode specified. Use 'QSPI', 'SPI', or 'DPI'.");
            end
        endcase

        // End simulation
        #20;
        $finish;
    end

    // Task to test all CPOL and CPHA combinations
    task test_modes;
        integer i, j;
        begin
            for (i = 0; i < 2; i = i + 1) begin
                for (j = 0; j < 2; j = j + 1) begin
                    CPOL = i;
                    CPHA = j;
                    
                    #10;
                    start = 1;
                    #10;
                    start = 0;

                    // Wait for the operation to complete
                    wait(done);

                    // Check results
                    #10;
                    $display("Test Mode with CPOL=%b, CPHA=%b:", CPOL, CPHA);
                    $display("Data Out: %h", data_out);
                    $display("Busy: %b", busy);
                    $display("Done: %b", done);
                    $display("IO Lines: %h", io_lines);
                    
                    #100; // Delay between tests
                end
            end
        end
    endtask

endmodule

//***********************************************************************************//
