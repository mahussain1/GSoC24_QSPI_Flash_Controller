`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2024 04:07:00 PM
// Design Name: 
// Module Name: qspi_spi_controller
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

//***********************************************************************************//

// ALL THREE SPI MODES ARE WORKING with CPOL CPHA
module qspi_spi_controller #(
    parameter DATA_WIDTH    = 4,        // Width of the data bus
    parameter ADDRESS_WIDTH = 32,       // Width of the address bus
    parameter COMMAND_WIDTH = 8,        // Width of the command bus
    parameter MODE          = MODE_SPI; // Select SPI modde

)(
    input wire                      clk,          // System clock
    input wire                      reset_n,      // Active-low reset
    input wire [DATA_WIDTH-1:0]     data_in,      // Data input
    output reg [DATA_WIDTH-1:0]     data_out,     // Data output
    input wire [COMMAND_WIDTH-1:0]  command,      // Command input
    input wire [ADDRESS_WIDTH-1:0]  address,      // Address input
    input wire                      start,        // Start signal for operation
    output reg                      busy,         // Busy signal
    output reg                      done,         // Done signal
    input wire                      CPOL,         // Clock Polarity
    input wire                      CPHA,         // Clock Phase
    inout wire [DATA_WIDTH-1:0]     io_lines      // IO lines for SPI, QSPI, and DPI
);
        
    // SPI mode definitions
    localparam MODE_SPI     = 2'b00;    // SPI  Mode will be active
    localparam MODE_DPI     = 2'b01;    // DPI Mode will be active
    localparam MODE_QSPI    = 2'b10;    // QSPI Mode will be active
    
    // State definitions
    localparam IDLE         = 3'b000;
    localparam COMMAND      = 3'b001;
    localparam ADDRESS      = 3'b010;
    localparam DATA         = 3'b011;
    localparam DONE         = 3'b100;
    
    reg [2:0] state, next_state;
    
    // SPI mode selection based on CPOL and CPHA
    reg [1:0] Sel_CPHA_CPOL; // 2-bit selection line
    
    // Signal registers for different modes
    reg [DATA_WIDTH-1:0] data_reg;
    reg [ADDRESS_WIDTH-1:0] address_reg;
    reg [COMMAND_WIDTH-1:0] command_reg;
    reg [DATA_WIDTH-1:0] spi_io_out, spi_io_out_next;
    reg spi_io_oe;
    reg [DATA_WIDTH-1:0] qspi_io_out;
    reg qspi_io_oe;
    reg [3:0] dpi_io_out; // Updated to 4 bits
    reg dpi_io_oe;

    // State transition and output logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            
            //SPI
            spi_io_out <= {DATA_WIDTH{1'bz}};
            spi_io_oe <= 1'b0;
            
            //QSPI
            qspi_io_out <= {DATA_WIDTH{1'bz}};
            qspi_io_oe <= 1'b0;
            
            //DPI
            dpi_io_out <= 4'bzzzz; // Set all bits to high impedance
            dpi_io_oe <= 1'b0;
        end else begin
            state <= next_state;
            spi_io_out <= spi_io_out_next;
        end
    end

    // Next state logic
    always @(*) begin
        busy = 1'b0; // Default assignment
        next_state = state;
        spi_io_out_next = {DATA_WIDTH{1'bz}};
        done = 1'b0;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = COMMAND;
                    busy = 1'b1;
                end
            end
            COMMAND: begin
                next_state = ADDRESS;
                //SPI
                if (MODE == MODE_SPI) begin
                    spi_io_out_next = command;
                    spi_io_oe = 1'b1; // Enable SPI output
                    
                //QSPI
                end else if (MODE == MODE_QSPI) begin
                    qspi_io_out = command;
                    qspi_io_oe = 1'b1; // Enable QSPI output
                    
                //DPI
                end else if (MODE == MODE_DPI) begin
                    dpi_io_out[3:2] = command[1:0]; // Use 2 bits for DPI
                    dpi_io_oe = 1'b1; // Enable DPI output
                end
            end
            ADDRESS: begin
                next_state = DATA;
                
                //SPI
                if (MODE == MODE_SPI) begin
                    spi_io_out_next = address;
                    spi_io_oe = 1'b1; // Enable SPI output
                    
                //QSPI
                end else if (MODE == MODE_QSPI) begin
                    qspi_io_out = address;
                    qspi_io_oe = 1'b1; // Enable QSPI output
                    
                //DPI
                end else if (MODE == MODE_DPI) begin
                    dpi_io_out[3:2] = address[1:0]; // Use 2 bits for DPI
                    dpi_io_oe = 1'b1; // Enable DPI output
                end
            end
            DATA: begin
                next_state = DONE;
                
                //SPI
                if (MODE == MODE_SPI) begin
                    spi_io_out_next = data_in;
                    spi_io_oe = 1'b1; // Enable SPI output
                
                //QSPI
                end else if (MODE == MODE_QSPI) begin
                    qspi_io_out = data_in;
                    qspi_io_oe = 1'b1; // Enable QSPI output
                    
                //DPI
                end else if (MODE == MODE_DPI) begin
                    dpi_io_out[3:2] = data_in[1:0]; // Use 2 bits for DPI
                    dpi_io_oe = 1'b1; // Enable DPI output
                end
            end
            DONE: begin
                next_state = IDLE;
                done = 1'b1;
                
                //SPI
                if (MODE == MODE_SPI) begin
                    spi_io_out_next = {DATA_WIDTH{1'bz}}; // High impedance
                    spi_io_oe = 1'b0; // Disable SPI output
                    
                //QSPI
                end else if (MODE == MODE_QSPI) begin
                    qspi_io_out = {DATA_WIDTH{1'bz}}; // High impedance
                    qspi_io_oe = 1'b0; // Disable QSPI output
                    
                //DPI
                end else if (MODE == MODE_DPI) begin
                    dpi_io_out[3:2] = 2'bzz; // High impedance
                    dpi_io_oe = 1'b0; // Disable DPI output
                end
            end
            default: begin
                next_state = IDLE;
                spi_io_out_next = {DATA_WIDTH{1'bz}}; // High impedance
                spi_io_oe = 1'b0; // Disable SPI output
            end
        endcase
    end

    // Output data assignment
    always @(posedge clk) begin
        if (state == DONE) begin
        
        //SPI
            if (MODE == MODE_SPI) begin
                data_out <= spi_io_out;
                     
         //QSPI
            end else if (MODE == MODE_QSPI) begin
                data_out <= qspi_io_out;
                
         //DPI 
            end else if (MODE == MODE_DPI) begin
                data_out[3:2] <= dpi_io_out[3:2]; // For DPI, data_out will use 2 bits
            end
        end
    end

    // Drive IO lines with tri-state buffers
    assign io_lines = (MODE == MODE_QSPI) ? (qspi_io_oe ? qspi_io_out : {DATA_WIDTH{1'bz}}) :
                      (MODE == MODE_SPI)  ? (spi_io_oe ? spi_io_out : {DATA_WIDTH{1'bz}}) :
                      (MODE == MODE_DPI)  ? (dpi_io_oe ? dpi_io_out[3:2] : 2'bzz) :
                                         {DATA_WIDTH{1'bz}};

    always @(*) begin
        case ({CPOL, CPHA})
            2'b00:   Sel_CPHA_CPOL = 2'b00;   // Mode 0: Sample on rising, Shift on falling
            2'b01:   Sel_CPHA_CPOL = 2'b01;   // Mode 1: Sample on falling, Shift on rising
            2'b10:   Sel_CPHA_CPOL = 2'b10;   // Mode 2: Sample on falling, Shift on rising
            2'b11:   Sel_CPHA_CPOL = 2'b11;   // Mode 3: Sample on rising, Shift on falling
            default: Sel_CPHA_CPOL = 2'b00;   // Default mode
        endcase
    end
endmodule

//***********************************************************************************//








