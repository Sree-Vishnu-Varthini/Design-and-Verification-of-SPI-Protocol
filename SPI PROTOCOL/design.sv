//===========================
// SPI Master Module
//===========================
module spi_master (
    input        clk,
    input        newd,
    input        rst,
    input  [11:0] din,
    output reg   sclk,
    output reg   cs,
    output reg   mosi
);

    typedef enum bit [1:0] {
        idle   = 2'b00,
        enable = 2'b01,
        send   = 2'b10,
        comp   = 2'b11
    } state_type;

    state_type state = idle;

    int countc = 0;
    int count  = 0;

    // Clock generation for SPI clock (sclk)
    always @(posedge clk) begin
        if (rst) begin
            countc <= 0;
            sclk   <= 1'b0;
        end else begin
            if (countc < 10)
                countc <= countc + 1;
            else begin
                countc <= 0;
                sclk   <= ~sclk;
            end
        end
    end

    // FSM variables
    reg [11:0] temp;

    // State Machine for SPI data transmission
    always @(posedge sclk) begin
        if (rst) begin
            cs   <= 1'b1;
            mosi <= 1'b0;
            state <= idle;
            count <= 0;
        end else begin
            case (state)
                idle: begin
                    if (newd) begin
                        temp  <= din;
                        cs    <= 1'b0;
                        state <= send;
                    end else begin
                        temp  <= 12'h000;
                        state <= idle;
                    end
                end

                send: begin
                    if (count <= 11) begin
                        mosi <= temp[count]; // Send LSB first
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        cs    <= 1'b1;
                        mosi  <= 1'b0;
                        state <= idle;
                    end
                end

                default: state <= idle;
            endcase
        end
    end

endmodule

//===========================
// SPI Slave Module
//===========================
module spi_slave (
    input        sclk,
    input        cs,
    input        mosi,
    output [11:0] dout,
    output reg   done
);

    typedef enum bit {
        detect_start = 1'b0,
        read_data    = 1'b1
    } state_type;

    state_type state = detect_start;

    reg [11:0] temp  = 12'h000;
    int        count = 0;

    always @(posedge sclk) begin
        case (state)
            detect_start: begin
                done <= 1'b0;
                if (cs == 1'b0)
                    state <= read_data;
                else
                    state <= detect_start;
            end

            read_data: begin
                if (count <= 11) begin
                    temp  <= {mosi, temp[11:1]};
                    count <= count + 1;
                end else begin
                    count <= 0;
                    done  <= 1'b1;
                    state <= detect_start;
                end
            end
        endcase
    end

    assign dout = temp;

endmodule

//===========================
// Top-Level Module
//===========================
module top (
    input        clk,
    input        rst,
    input        newd,
    input  [11:0] din,
    output [11:0] dout,
    output       done
);

    wire sclk, cs, mosi;

    spi_master m1 (
        .clk(clk),
        .newd(newd),
        .rst(rst),
        .din(din),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi)
    );

    spi_slave s1 (
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .dout(dout),
        .done(done)
    );
 
endmodule
