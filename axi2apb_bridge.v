// Simple AXI4-Lite to APB bridge
module axi2apb_bridge #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  wire                     aclk,
    input  wire                     aresetn,

    // AXI4-Lite write address channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,

    // AXI4-Lite write data channel
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,

    // AXI4-Lite write response channel
    output reg [1:0]                s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,

    // AXI4-Lite read address channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,

    // AXI4-Lite read data channel
    output reg [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg [1:0]                s_axi_rresp,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready,

    // APB interface
    output reg [ADDR_WIDTH-1:0]     paddr,
    output reg                      pwrite,
    output reg                      psel,
    output reg                      penable,
    output reg [DATA_WIDTH-1:0]     pwdata,
    input  wire [DATA_WIDTH-1:0]    prdata,
    input  wire                     pready,
    input  wire                     pslverr
);

    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;

    localparam ST_IDLE         = 3'd0;
    localparam ST_WRITE_SETUP  = 3'd1;
    localparam ST_WRITE_ACCESS = 3'd2;
    localparam ST_WRITE_RESP   = 3'd3;
    localparam ST_READ_SETUP   = 3'd4;
    localparam ST_READ_ACCESS  = 3'd5;
    localparam ST_READ_RESP    = 3'd6;

    reg [2:0]                  state, state_next;
    reg [ADDR_WIDTH-1:0]       awaddr_reg;
    reg [DATA_WIDTH-1:0]       wdata_reg;
    reg [ADDR_WIDTH-1:0]       araddr_reg;
    reg                        aw_pending;
    reg                        w_pending;
    reg                        ar_pending;

    wire aw_hs = s_axi_awvalid && s_axi_awready;
    wire w_hs  = s_axi_wvalid  && s_axi_wready;
    wire ar_hs = s_axi_arvalid && s_axi_arready;

    // State register
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= ST_IDLE;
        end else begin
            state <= state_next;
        end
    end

    // Capture write and read requests
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
            wdata_reg  <= {DATA_WIDTH{1'b0}};
            araddr_reg <= {ADDR_WIDTH{1'b0}};
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;
            ar_pending <= 1'b0;
        end else begin
            if (aw_hs) begin
                awaddr_reg <= s_axi_awaddr;
                aw_pending <= 1'b1;
            end else if (state == ST_WRITE_RESP && s_axi_bvalid && s_axi_bready) begin
                aw_pending <= 1'b0;
            end

            if (w_hs) begin
                wdata_reg <= s_axi_wdata;
                w_pending <= 1'b1;
            end else if (state == ST_WRITE_RESP && s_axi_bvalid && s_axi_bready) begin
                w_pending <= 1'b0;
            end

            if (ar_hs) begin
                araddr_reg <= s_axi_araddr;
                ar_pending <= 1'b1;
            end else if (state == ST_READ_RESP && s_axi_rvalid && s_axi_rready) begin
                ar_pending <= 1'b0;
            end
        end
    end

    // Read data capture
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_rdata <= {DATA_WIDTH{1'b0}};
        end else if (state == ST_READ_ACCESS && pready) begin
            s_axi_rdata <= prdata;
        end
    end

    // Next state logic and output control
    always @(*) begin
        s_axi_awready = (state == ST_IDLE) && !aw_pending;
        s_axi_wready  = (state == ST_IDLE) && !w_pending;
        s_axi_arready = (state == ST_IDLE) && !aw_pending && !w_pending && !ar_pending;

        s_axi_bvalid  = 1'b0;
        s_axi_bresp   = RESP_OKAY;
        s_axi_rvalid  = 1'b0;
        s_axi_rresp   = RESP_OKAY;

        paddr   = {ADDR_WIDTH{1'b0}};
        pwdata  = {DATA_WIDTH{1'b0}};
        pwrite  = 1'b0;
        psel    = 1'b0;
        penable = 1'b0;

        state_next = state;

        case (state)
            ST_IDLE: begin
                if (aw_pending && w_pending) begin
                    state_next = ST_WRITE_SETUP;
                end else if (ar_pending) begin
                    state_next = ST_READ_SETUP;
                end
            end

            ST_WRITE_SETUP: begin
                paddr  = awaddr_reg;
                pwdata = wdata_reg;
                pwrite = 1'b1;
                psel   = 1'b1;
                penable = 1'b0;
                state_next = ST_WRITE_ACCESS;
            end

            ST_WRITE_ACCESS: begin
                paddr  = awaddr_reg;
                pwdata = wdata_reg;
                pwrite = 1'b1;
                psel   = 1'b1;
                penable = 1'b1;
                if (pready) begin
                    state_next = ST_WRITE_RESP;
                end
            end

            ST_WRITE_RESP: begin
                s_axi_bvalid = 1'b1;
                s_axi_bresp  = pslverr ? RESP_SLVERR : RESP_OKAY;
                if (s_axi_bvalid && s_axi_bready) begin
                    state_next = ST_IDLE;
                end
            end

            ST_READ_SETUP: begin
                paddr  = araddr_reg;
                pwrite = 1'b0;
                psel   = 1'b1;
                penable = 1'b0;
                state_next = ST_READ_ACCESS;
            end

            ST_READ_ACCESS: begin
                paddr  = araddr_reg;
                pwrite = 1'b0;
                psel   = 1'b1;
                penable = 1'b1;
                if (pready) begin
                    state_next = ST_READ_RESP;
                end
            end

            ST_READ_RESP: begin
                s_axi_rvalid = 1'b1;
                s_axi_rresp  = pslverr ? RESP_SLVERR : RESP_OKAY;
                if (s_axi_rvalid && s_axi_rready) begin
                    state_next = ST_IDLE;
                end
            end

            default: begin
                state_next = ST_IDLE;
            end
        endcase
    end

endmodule
