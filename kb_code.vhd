library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kb_code is
	generic(W_SIZE : integer := 2);
	port(
		clk, reset : in std_logic;
		ps2d, ps2c : in std_logic;
		key_code : out std_logic_vector(7 downto 0);
		p1_up_tick, p2_up_tick, p1_down_tick, p2_down_tick : out std_logic
	);
end kb_code;

architecture arch of kb_code is
	constant BRK : std_logic_vector(7 downto 0) := "11110000";
	constant P1_UP : std_logic_vector(7 downto 0) := "00011100";
	constant P1_DOWN : std_logic_vector(7 downto 0) := "00011010";
	constant P2_UP : std_logic_vector(7 downto 0) := "01001011";
	constant P2_DOWN : std_logic_vector(7 downto 0) := "01000001";
	
	type statetype is(init, get_code);
	signal state_reg, state_next : statetype;
	signal scan_out : std_logic_vector(7 downto 0);
	signal p1_up_reg, p2_up_reg, p1_down_reg, p2_down_reg : std_logic;
	signal p1_up_next, p2_up_next, p1_down_next, p2_down_next : std_logic;
	signal scan_done_tick : std_logic;
begin
	ps2_rx_unit : entity work.ps2_rx(arch)
		port map(clk => clk, reset => reset, rx_en => '1',
					ps2d => ps2d, ps2c => ps2c,
					rx_done_tick => scan_done_tick,
					dout => scan_out);
	process(clk, reset)
	begin
		if reset = '1' then
			state_reg <= init;
			p1_up_reg <= '0';
			p1_down_reg <= '0';
			p2_up_reg <= '0';
			p2_down_reg <= '0';
		elsif(clk'event and clk = '1') then
			state_reg <= state_next;
			p1_up_reg <= p1_up_next;
			p1_down_reg <= p1_down_next;
			p2_up_reg <= p2_up_next;
			p2_down_reg <= p2_down_next;
		end if;
	end process;
	
	process(state_reg, scan_done_tick, p1_up_reg, p2_up_reg, p1_down_reg, p2_down_reg, scan_out)
	begin
		state_next <= state_reg;
		p1_up_next <= p1_up_reg;
		p1_down_next <= p1_down_reg;
		p2_up_next <= p2_up_reg;
		p2_down_next <= p2_down_reg;
		case state_reg is 
			when init => 
				if scan_done_tick = '1' then
					if scan_out = BRK then
						state_next <= get_code;
					else
						if scan_out = P1_UP then
							p1_up_next <= '1';
						elsif scan_out = P1_DOWN then
							p1_down_next <= '1';
						elsif scan_out = P2_UP then
							p2_up_next <= '1';
						elsif scan_out = P2_DOWN then
							p2_down_next <= '1';
						end if;
					end if;
				end if;
			when get_code =>
				if scan_done_tick = '1' then
					if scan_out = P1_UP then
							p1_up_next <= '0';
						elsif scan_out = P1_DOWN then
							p1_down_next <= '0';
						elsif scan_out = P2_UP then
							p2_up_next <= '0';
						elsif scan_out = P2_DOWN then
							p2_down_next <= '0';
						end if;
					state_next <= init;
				end if;
		end case;
	end process;
	p1_up_tick <= p1_up_reg;
	p1_down_tick <= p1_down_reg;
	p2_up_tick <= p2_up_reg;
	p2_down_tick <= p2_down_reg;
end arch;