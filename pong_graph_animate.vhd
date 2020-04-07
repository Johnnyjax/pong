library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_graph_animate is
	port(
		clk, reset : std_logic;
		btn : std_logic_vector(3 downto 0);
		video_on : in std_logic;
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		p1_hit, p1_miss : out std_logic;
		p2_hit, p2_miss : out std_logic;
		gra_still : in std_logic;
		graph_on : out std_logic;
		graph_rgb : out std_logic_vector(2 downto 0)
	);
end pong_graph_animate;

architecture arch of pong_graph_animate is
	signal refr_tick : std_logic;
	signal pix_x, pix_y : unsigned(9 downto 0);
	
	constant MAX_X : integer := 640;
	constant MAX_Y : integer := 480;
	
	constant WALL_X_L : integer := 319;
	constant WALL_X_R : integer := 321;
	
	constant BAR1_X_L : integer:= 600;
	constant BAR1_X_R : integer := 603;
	
	signal bar1_y_t, bar1_y_b : unsigned(9 downto 0);
	constant BAR1_Y_SIZE : integer:= 60;
	signal bar1_y_reg, bar1_y_next : unsigned(9 downto 0);
	constant BAR_V : integer := 4;
	
	constant BAR2_X_L : integer:= 40;
	constant BAR2_X_R : integer := 43;
	
	signal bar2_y_t, bar2_y_b : unsigned(9 downto 0);
	constant BAR2_Y_SIZE : integer:= 60;
	signal bar2_y_reg, bar2_y_next : unsigned(9 downto 0);
	
	
	constant BALL_SIZE : integer:= 8;
	signal ball_x_l, ball_x_r : unsigned(9 downto 0);
	signal ball_y_t, ball_y_b : unsigned(9 downto 0);
	signal ball_x_reg, ball_x_next : unsigned(9 downto 0);
	signal ball_y_reg, ball_y_next : unsigned(9 downto 0);
	signal x_delta_reg, x_delta_next : unsigned(9 downto 0);
	signal y_delta_reg, y_delta_next : unsigned(9 downto 0);
	
	constant BALL_V_P : unsigned(9 downto 0) := to_unsigned(2, 10);
	constant BALL_V_N : unsigned(9 downto 0) := to_unsigned(-2, 10);
	
	type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
	constant BALL_ROM : rom_type := 
		(
			"00111100",
			"01111110",
			"11111111",
			"11111111",
			"11111111",
			"11111111",
			"01111110",
			"00111100"
		);
	signal rom_addr, rom_col : unsigned(2 downto 0);
	signal rom_data: std_logic_vector(7 downto 0);
	signal rom_bit : std_logic;
	
	signal wall_on, bar1_on, bar2_on, sq_ball_on, rd_ball_on : std_logic;
	signal wall_rgb, bar_rgb, ball_rgb : std_logic_vector(2 downto 0);
	
begin
	process(clk, reset)
	begin
		if reset = '1' then
			bar1_y_reg <= (others => '0');
			bar2_y_reg <= (others => '0');
			ball_x_reg <= (others => '0');
			ball_y_reg <= (others => '0');
			x_delta_reg <= ("0000000100");
			y_delta_reg <= ("0000000100");
		elsif(clk'event and clk = '1') then
			bar1_y_reg <= bar1_y_next;
			bar2_y_reg <= bar2_y_next;
			ball_x_reg <= ball_x_next;
			ball_y_reg <= ball_y_next;
			x_delta_reg <= x_delta_next;
			y_delta_reg <= y_delta_next;
		end if;
	end process;
	
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
	
	refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else
					 '0';
	wall_on <= 
		'1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else
		'0';
	wall_rgb <= "001";
	
	bar1_y_t <= bar1_y_reg;
	bar1_y_b <= bar1_y_t + BAR1_Y_SIZE - 1;
	bar1_on <= 
		'1' when (BAR1_X_L <= pix_x) and (pix_x <= BAR1_X_R) and
					(bar1_y_t <= pix_y) and (pix_y <= bar1_y_b) else
		'0';
	bar_rgb <= "010";
	process(bar1_y_reg, bar1_y_b, bar1_y_t, refr_tick, btn)
	begin
		bar1_y_next <= bar1_y_reg;
		if refr_tick = '1' then
			if btn(1) = '1' and bar1_y_b < (MAX_Y-1-BAR_V) then
				bar1_y_next <= bar1_y_reg + BAR_V;
			elsif btn(0) = '1' and bar1_y_t > BAR_V then
				bar1_y_next <= bar1_y_reg - BAR_V;
			end if;
		end if;
	end process;
	
	bar2_y_t <= bar2_y_reg;
	bar2_y_b <= bar2_y_t + BAR2_Y_SIZE - 1;
	bar2_on <= 
		'1' when (BAR2_X_L <= pix_x) and (pix_x <= BAR2_X_R) and
					(bar2_y_t <= pix_y) and (pix_y <= bar2_y_b) else
		'0';
	bar_rgb <= "010";
	process(bar2_y_reg, bar2_y_b, bar2_y_t, refr_tick, btn)
	begin
		bar2_y_next <= bar2_y_reg;
		if refr_tick = '1' then
			if btn(3) = '1' and bar2_y_b < (MAX_Y-1-BAR_V) then
				bar2_y_next <= bar2_y_reg + BAR_V;
			elsif btn(2) = '1' and bar2_y_t > BAR_V then
				bar2_y_next <= bar2_y_reg - BAR_V;
			end if;
		end if;
	end process;
	
	ball_x_l <= ball_x_reg;
	ball_y_t <= ball_y_reg;
	ball_x_r <= ball_x_l + BALL_SIZE-1;
	ball_y_b <= ball_y_t + BALL_SIZE-1;
			
	sq_ball_on <= 
		'1' when (ball_x_l <= pix_x) and (pix_x <= ball_x_r) and	
					 (ball_y_t <= pix_y) and (pix_y <= ball_y_b) else
		'0';
	rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);
	rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);
	rom_data <= BALL_ROM(to_integer(rom_addr));
	rom_bit <= rom_data(to_integer(rom_col));
	
	rd_ball_on <= 
		'1' when (sq_ball_on = '1') and (rom_bit = '1') else
		'0';
	ball_rgb <= "110";
	
	ball_x_next <=
		to_unsigned((MAX_X/2), 10) when gra_still = '1' else
		ball_x_reg + x_delta_reg when refr_tick = '1' else
		ball_x_reg;
	ball_y_next <= 
		to_unsigned((MAX_Y/2), 10) when gra_still = '1' else
		ball_y_reg + y_delta_reg when refr_tick = '1' else
		ball_y_reg;
	process(x_delta_reg, y_delta_reg, ball_y_t, ball_x_l, ball_x_r, gra_still,
			 ball_y_b, bar1_y_t, bar1_y_b, bar2_y_t, bar2_y_b)
	begin
		p1_hit <= '0';
		p1_miss <= '0';
		p2_hit <= '0';
		p2_miss <= '0';
		x_delta_next <= x_delta_reg;
		y_delta_next <= y_delta_reg;
		if ball_y_t < 1 then
			y_delta_next <= BALL_V_P;
		elsif ball_y_b > (MAX_Y-1) then
			y_delta_next <= BALL_V_N;
		elsif (ball_x_l <= BAR2_X_R) and (ball_x_l >= BAR2_X_L) and
			(bar2_y_t <= ball_y_b) and (ball_y_t <= bar2_y_b) then
				x_delta_next <= BALL_V_P;
				p1_hit <= '1';
		elsif (BAR1_X_L <= ball_x_r) and (ball_x_r <= BAR1_X_R) and
			(bar1_y_t <= ball_y_b) and (ball_y_t <= bar1_y_b) then
				x_delta_next <= BALL_V_N;
				p2_hit <= '1';
		elsif(ball_x_r > MAX_X) then
			p2_miss <= '1';
		elsif(ball_x_l < 2) then
			p1_miss <= '1';
		end if;
	end process;
	
	process(video_on, wall_on, bar1_on, bar2_on, rd_ball_on,
				wall_rgb, bar_rgb, ball_rgb)
	begin
		if video_on = '0' then
			graph_rgb <= "000";
		else
			if wall_on = '1' then
				graph_rgb <= wall_rgb;
			elsif bar1_on = '1' or bar2_on = '1' then
				graph_rgb <= bar_rgb;
			elsif rd_ball_on = '1' then
				graph_rgb <= ball_rgb;
			else 
				graph_rgb <= "000";
			end if;
		end if;
	end process;
	graph_on <= wall_on or bar1_on or bar2_on or rd_ball_on;
end arch;