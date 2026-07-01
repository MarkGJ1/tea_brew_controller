library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity string_e is
    port(
        cp_i       : in  std_logic;
        rb_i       : in  std_logic;
        brew_i     : in  std_logic; -- 
        min_i      : in  std_logic; --
        guess_i    : in  std_logic; -- Timer enable signals
        done_i     : in  std_logic; -- 
        bcd_byte_i : in  std_logic_vector(7 downto 0); -- TWI-RX signals
        bcd_dv_i   : in  std_logic; 
        tx_done_i  : in  std_logic; -- UART TX signals
        byte_o     : out std_logic_vector(7 downto 0);
        dv_o       : out std_logic
    );
end entity;

architecture string_a of string_e is

    constant CR_c : std_logic_vector(7 downto 0) := x"0D";
    constant LF_c : std_logic_vector(7 downto 0) := x"0A";

    constant BREW_LEN_c  : integer := 11;
    constant MIN_LEN_c   : integer := 23;
    constant GUESS_LEN_c : integer := 23;
    constant DONE_LEN_c  : integer := 23;
    constant MAX_LEN_c   : integer := 23;

    type rom_t   is array (0 to MAX_LEN_c  - 1) of std_logic_vector(7 downto 0);
    type brew_t  is array (0 to BREW_LEN_c - 1) of std_logic_vector(7 downto 0);
    type src_t   is (SRC_ROM, SRC_BREW);
    type state_t is (IDLE, LOAD, SEND);

    constant MIN1_STR_c : rom_t := (
        x"46", x"69", x"72", x"73", x"74", x"20",  -- "First "
        x"4D", x"69", x"6E", x"75", x"74", x"65",  -- "Minute"
        x"20", x"70", x"61", x"73", x"73", x"65",  -- " passe"
        x"64", x"2E", x"00",                        -- "d. "
        CR_c, LF_c
    );

    constant MIN2_STR_c : rom_t := (
        x"53", x"65", x"63", x"6F", x"6E", x"64",  -- "Second"
        x"20", x"4D", x"69", x"6E", x"75", x"74",  -- " Minut"
        x"65", x"20", x"70", x"61", x"73", x"73",  -- "e pass"
        x"65", x"64", x"2E",                        -- "ed."
        CR_c, LF_c
    );

    constant MIN3_STR_c : rom_t := (
        x"54", x"68", x"69", x"72", x"64", x"20",  -- "Third "
        x"4D", x"69", x"6E", x"75", x"74", x"65",  -- "Minute"
        x"20", x"70", x"61", x"73", x"73", x"65",  -- " passe"
        x"64", x"2E", x"00",                        -- "d. "
        CR_c, LF_c
    );

    constant MIN4_STR_c : rom_t := (
        x"46", x"6F", x"75", x"72", x"74", x"68",  -- "Fourth"
        x"20", x"4D", x"69", x"6E", x"75", x"74",  -- " Minut"
        x"65", x"20", x"70", x"61", x"73", x"73",  -- "e pass"
        x"65", x"64", x"2E",                        -- "ed."
        CR_c, LF_c
    );

    constant GUESS_STR_c : rom_t := (
        x"2E", x"2E", x"2E",                        -- "..."
        x"67", x"75", x"65", x"73", x"73", x"20",  -- "guess "
        x"77", x"68", x"61", x"74",                 -- "what"
        x"2E", x"2E", x"2E",                        -- "..."
        CR_c, LF_c,
        x"00", x"00", x"00", x"00", x"00"           -- padding
    );

    constant DONE_STR_c : rom_t := (
        x"54", x"65", x"61", x"20",                 -- "Tea "
        x"69", x"73", x"20",                        -- "is "
        x"72", x"65", x"61", x"64", x"79",          -- "ready"
        CR_c, LF_c,
        x"00", x"00", x"00", x"00", x"00",          -- padding
        x"00", x"00", x"00", x"00"
    );

    -- FSM state registers
    signal state_r      : state_t;
    signal next_state_w : state_t;

    -- Datapath registers
    signal src_r      : src_t;
    signal rom_r      : rom_t;
    signal brew_buf_r : brew_t;
    signal idx_r      : integer range 0 to MAX_LEN_c - 1;
    signal len_r      : integer range 0 to MAX_LEN_c;
    signal min_i_r    : std_logic; -- second FF
    signal min_cnt_r  : integer range 0 to 3;

    -- BCD byte latch registers (filled by TWI-RX interface)
    -- Order: SS(0) -> MM(1) -> HH(2) -> E(3)
    signal bcd_ss_r  : std_logic_vector(7 downto 0);
    signal bcd_mm_r  : std_logic_vector(7 downto 0);
    signal bcd_hh_r  : std_logic_vector(7 downto 0);
    signal bcd_e_r   : std_logic_vector(7 downto 0);
    signal bcd_cnt_r : integer range 0 to 3;

begin

    -- -------------------------------------------------------------------------
    -- Process 1: State register
    -- -------------------------------------------------------------------------
    p_state_reg : process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            state_r <= IDLE;
        elsif rising_edge(cp_i) then
            state_r <= next_state_w;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- Process 2: Next-state logic (combinational)
    -- -------------------------------------------------------------------------
    p_next_state : process(state_r, done_i, guess_i, brew_i, min_i_r,
                           tx_done_i, idx_r, len_r)
    begin
        next_state_w <= state_r;  -- default: stay
        case state_r is
            when IDLE =>
                if done_i = '1' then
                    next_state_w <= LOAD;
                elsif guess_i = '1' then
                    next_state_w <= LOAD;
                elsif brew_i = '1' then
                    next_state_w <= LOAD;
                elsif min_i_r = '1' then
                    next_state_w <= LOAD;
                end if;
            when LOAD =>
                next_state_w <= SEND;
            when SEND =>
                if tx_done_i = '1' and idx_r = len_r - 1 then
                    next_state_w <= IDLE;
                end if;
            when others => next_state_w <= IDLE;
        end case;
    end process;

    -- -------------------------------------------------------------------------
    -- Process 3: Datapath registers + output logic (clocked)
    -- Drives byte_o, dv_o and updates all _r registers.
    -- -------------------------------------------------------------------------
    p_datapath : process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            src_r      <= SRC_ROM;
            rom_r      <= (others => (others => '0'));
            brew_buf_r <= (others => (others => '0'));
            idx_r      <= 0;
            len_r      <= 0;
            min_i_r    <= '0';
            min_cnt_r  <= 0;
            byte_o     <= (others => '0');
            dv_o       <= '0';
            bcd_ss_r   <= (others => '0');
            bcd_mm_r   <= (others => '0');
            bcd_hh_r   <= (others => '0');
            bcd_e_r    <= (others => '0');
            bcd_cnt_r  <= 0;
        elsif rising_edge(cp_i) then
            dv_o    <= '0';  -- default
            min_i_r <= min_i;
            -- -----------------------------------------------------------------
            -- Always-active BCD byte latch
            -- Captures incoming bytes regardless of FSM state so no pulse
            -- is missed during SEND.
            -- -----------------------------------------------------------------
            if bcd_dv_i = '1' then
                case bcd_cnt_r is
                    when 0 => bcd_ss_r <= bcd_byte_i;
                    when 1 => bcd_mm_r <= bcd_byte_i;
                    when 2 => bcd_hh_r <= bcd_byte_i;
                    when 3 => bcd_e_r  <= bcd_byte_i;
                end case;
                if bcd_cnt_r = 3 then
                    bcd_cnt_r <= 0;
                else
                    bcd_cnt_r <= bcd_cnt_r + 1;
                end if;
            end if;

            -- -----------------------------------------------------------------
            -- Datapath actions, indexed by current state
            -- -----------------------------------------------------------------
            case state_r is

                when IDLE =>
                    if done_i = '1' then
                        min_cnt_r  <= 0;
                        rom_r      <= DONE_STR_c;
                        len_r      <= DONE_LEN_c;
                        src_r      <= SRC_ROM;
                        idx_r      <= 0;

                    elsif guess_i = '1' then
                        rom_r  <= GUESS_STR_c;
                        len_r  <= GUESS_LEN_c;
                        src_r  <= SRC_ROM;
                        idx_r  <= 0;

                    elsif brew_i = '1' then
                        brew_buf_r(0)  <= std_logic_vector(
                                            resize(unsigned(bcd_hh_r(7 downto 4)), 8) + 48);
                        brew_buf_r(1)  <= std_logic_vector(
                                            resize(unsigned(bcd_hh_r(3 downto 0)), 8) + 48);
                        brew_buf_r(2)  <= x"3A";
                        brew_buf_r(3)  <= std_logic_vector(
                                            resize(unsigned(bcd_mm_r(7 downto 4)), 8) + 48);
                        brew_buf_r(4)  <= std_logic_vector(
                                            resize(unsigned(bcd_mm_r(3 downto 0)), 8) + 48);
                        brew_buf_r(5)  <= x"3A";
                        brew_buf_r(6)  <= std_logic_vector(
                                            resize(unsigned(bcd_ss_r(7 downto 4)), 8) + 48);
                        brew_buf_r(7)  <= std_logic_vector(
                                            resize(unsigned(bcd_ss_r(3 downto 0)), 8) + 48);
                        brew_buf_r(8)  <= x"45";
                        brew_buf_r(9)  <= CR_c;
                        brew_buf_r(10) <= LF_c;
                        len_r  <= BREW_LEN_c;
                        src_r  <= SRC_BREW;
                        idx_r  <= 0;

                    elsif min_i_r = '1' then
                        case min_cnt_r is
                            when 0 => rom_r <= MIN1_STR_c;
                            when 1 => rom_r <= MIN2_STR_c;
                            when 2 => rom_r <= MIN3_STR_c;
                            when 3 => rom_r <= MIN4_STR_c;
                        end case;
                        if min_cnt_r = 3 then
                            min_cnt_r <= 0;
                        else
                            min_cnt_r <= min_cnt_r + 1;
                        end if;
                        len_r  <= MIN_LEN_c;
                        src_r  <= SRC_ROM;
                        idx_r  <= 0;
                    end if;

                when LOAD =>
                    case src_r is
                        when SRC_ROM  => byte_o <= rom_r(0);
                        when SRC_BREW => byte_o <= brew_buf_r(0);
                    end case;
                    dv_o <= '1';

                when SEND =>
                    if done_i = '1' then
                        min_cnt_r  <= 0;
                    end if;

                    if tx_done_i = '1' then
                        if idx_r /= len_r - 1 then
                            idx_r <= idx_r + 1;
                            case src_r is
                                when SRC_ROM  => byte_o <= rom_r(idx_r + 1);
                                when SRC_BREW => byte_o <= brew_buf_r(idx_r + 1);
                            end case;
                            dv_o <= '1';
                        end if;
                    end if;

            end case;
        end if;
    end process;

end architecture;