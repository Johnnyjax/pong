library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_top_an is
	port(
		CLOCK_50 : in std_logic;
		KEY      : in std_logic_vector(0 downto 0);
		VGA_HS, VGA_VS : out std_logic;
		VGA_R, VGA_B, VGA_G : out std_logic_vector(2 downto 0);
		LEDG : out std_logic_vector(2 downto 0);
		PS2_DAT, PS2_CLK : in std_logic
	);
end pong_top_an;

architecture arch of pong_top_an is
	type state_type is (newgame, play, newball, over);
	signal video_on, pixel_tick : std_logic;
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal graph_on, gra_still, p1_hit, p1_miss, p2_hit, p2_miss: std_logic;
	signal text_on : std_logic_vector(5 downto 0);
	signal graph_rgb, text_rgb : std_logic_vector(2 downto 0);
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
	signal state_reg, state_next : state_type;
	signal p1_dig0, p1_dig1 : std_logic_vector(3 downto 0);
	signal p2_dig0, p2_dig1 : std_logic_vector(3 downto 0);
	signal win_dig : std_logic_vector(3 downto 0);
	signal p1_d_inc, p1_d_clr : std_logic;
	signal p2_d_inc, p2_d_clr : std_logic;
	signal timer_tick, timer_start, timer_up : std_logic;
	signal p1_ball_reg, p1_ball_next : unsigned(1 downto 0);
	signal p2_ball_reg, p2_ball_next : unsigned(1 downto 0);
	signal p1_ball : std_logic_vector(1 downto 0);
	signal p2_ball : std_logic_vector(1 downto 0);
	signal control : std_logic_vector(3 downto 0);
	signal key_code : std_logic_vector(7 downto 0);
begin
	kb_code_unit : entity work.kb_code(arch)
		port map(clk => CLOCK_50, reset => not(KEY(0)), ps2d => PS2_DAT, ps2c => PS2_CLK,
					key_code => key_code, p1_up_tick => control(2), p1_down_tick => control(3),
					p2_up_tick => control(0), p2_down_tick => control(1));

	vga_sync_unit : entity work.vga_sync
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					video_on => video_on, p_tick => pixel_tick,
					hsync => VGA_HS, vsync => VGA_VS, 
					pixel_x => pixel_x, pixel_y => pixel_y);
					
	p1_ball <= std_logic_vector(p1_ball_reg);
	p2_ball <= std_logic_vector(p2_ball_reg);
	text_unit : entity work.pong_text
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					pixel_x => pixel_x, pixel_y => pixel_y, ball2 => p2_ball,
					p1_dig0 => p1_dig0, p1_dig1 => p1_dig1, ball1 => p1_ball,
					text_on => text_on, text_rgb => text_rgb, win_dig => win_dig,
					p2_dig0 => p2_dig0, p2_dig1 => p2_dig1);
					
	pong_graph_an_unit : entity work.pong_graph_animate
		port map(clk => CLOCK_50, reset => not(KEY(0)), 
					btn => control, video_on => video_on,
					p1_hit => p1_hit, graph_on => graph_on, gra_still => gra_still,
					p1_miss => p1_miss, p2_hit => p2_hit, p2_miss => p2_miss,
					pixel_x => pixel_x, pixel_y => pixel_y, graph_rgb => graph_rgb);
	
	timer_tick <= 
		'1' when pixel_x = "0000000000" and 
					pixel_y = "0000000000" else
		'0';
	timer_unit : entity work.timer
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					timer_tick => timer_tick,
					timer_start => timer_start,
					timer_up => timer_up);
	counter1_unit : entity work.m100_counter
		port map(clk => CLOCK_50, reset => not(KEY(0)),
		d_inc => p1_d_inc, d_clr => p1_d_clr, dig0 => p1_dig0, dig1 => p1_dig1);
	counter2_unit : entity work.m100_counter
		port map(clk => CLOCK_50, reset => not(KEY(0)),
		d_inc => p2_d_inc, d_clr => p2_d_clr, dig0 => p2_dig0, dig1 => p2_dig1);
					
	process(CLOCK_50, KEY(0))
	begin
		if KEY(0) = '0' then
			state_reg <= newgame;
			p1_ball_reg <= (others => '0');
			p2_ball_reg <= (others => '0');
			rgb_reg <= (others => '0');
		elsif(CLOCK_50'event and CLOCK_50 = '1') then
			state_reg <= state_next;
			p1_ball_reg <= p1_ball_next;
			p2_ball_reg <= p2_ball_next;
			if (pixel_tick = '1') then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	
	process(control, p1_hit, p1_miss, p2_hit, p2_miss, timer_up, state_reg,
				p1_ball_reg, p1_ball_next, p2_ball_reg, p2_ball_next,
				p1_dig0, p1_dig1, p2_dig0, p2_dig1)
	begin	
		win_dig <= (others => '0');
		gra_still <= '1';
		timer_start <= '0';
		p1_d_inc <= '0';
		p1_d_clr <= '0';
		p2_d_inc <= '0';
		p2_d_clr <= '0';
		state_next <= state_reg;
		p1_ball_next <= p1_ball_reg;
		p2_ball_next <= p2_ball_reg;

		case state_reg is
			when newgame =>
				p1_ball_next <= "11";
				p2_ball_next <= "11";
				p1_d_clr <= '1';
				p2_d_clr <= '1';
				if(control /= "0000") then
					state_next <= play;
					p1_ball_next <= p1_ball_reg - 1;
					p2_ball_next <= p2_ball_reg - 1;
				end if;
			when play =>
				gra_still <= '0';
				if p1_hit = '1' then
					p1_d_inc <= '1';
				elsif p2_hit = '1' then
					p2_d_inc <= '1';
				elsif p1_miss = '1' then
					if(p1_ball_reg = 0) then
						state_next <= over;
					else
						state_next <= newball;
					end if;
					timer_start <= '1';
					p1_ball_next <= p1_ball_reg-1;
				elsif p2_miss = '1' then
					if(p2_ball_reg = 0) then
						state_next <= over;
					else
						state_next <= newball;
					end if;
					timer_start <= '1';
					p2_ball_next <= p2_ball_reg-1; 
				end if;
			when newball =>
				if ((timer_up = '1') and (control /= "0000")) then
					state_next <= play;
				end if;
			when over =>
				if(p1_dig1 > p2_dig1) then
					win_dig <= "0001";
				elsif(p1_dig1 < p2_dig1) then
					win_dig <= "0010";
				else
					if(p1_dig0 > p2_dig0) then
						win_dig <= "0001";
					elsif p1_dig0 < p2_dig0 then
						win_dig <= "0010";
					else
						win_dig <= "0000";
					end if;
				end if;
				if timer_up = '1' then
					state_next <= newgame;
				end if;
		end case;
	end process;
	
	process(state_reg, video_on, graph_on, graph_rgb, text_on, text_rgb)
	begin
		if video_on = '0' then
			rgb_next <= "000";
		else
			if(text_on(3) = '1') or text_on(4) = '1' or
				(state_reg = newgame and text_on(1) = '1') or
				(state_reg = over and text_on(0) = '1') or
			   (state_reg = over and text_on(5) = '1') then
				rgb_next <= text_rgb;
			elsif graph_on = '1' then
				rgb_next <= graph_rgb;
			elsif text_on(2) = '1' then
				rgb_next <= text_rgb;
			else
				rgb_next <= "000";
			end if;
		end if;
	end process;
	VGA_R <= (others => rgb_reg(2));
	VGA_G <= (others => rgb_reg(1));
	VGA_B <= (others => rgb_reg(0));
end arch;