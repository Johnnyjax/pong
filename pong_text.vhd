library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_text is
	port(
		clk, reset : in std_logic;
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		p1_dig0, p1_dig1 : in std_logic_vector(3 downto 0);
		p2_dig0, p2_dig1 : in std_logic_vector(3 downto 0);
		win_dig          : in std_logic_vector(3 downto 0);
		ball1 : in std_logic_vector(1 downto 0);
		ball2 : in std_logic_vector(1 downto 0);
		text_on : out std_logic_vector(5 downto 0);
		text_rgb : out std_logic_vector(2 downto 0)
	);
end pong_text;

architecture arch of pong_text is
	signal pix_x, pix_y : unsigned(9 downto 0);
	signal rom_addr : std_logic_vector(10 downto 0);
	signal char_addr, char_addr_s1, char_addr_s2, char_addr_l, char_addr_r,
			 char_addr_o, char_addr_p : std_logic_vector(6 downto 0);
	signal row_addr, row_addr_s1, row_addr_s2, row_addr_l, row_addr_r,
			 row_addr_o, row_addr_p : std_logic_vector(3 downto 0);
	signal bit_addr, bit_addr_s1, bit_addr_s2, bit_addr_l, bit_addr_r,
			 bit_addr_o, bit_addr_p : std_logic_vector(2 downto 0);
	signal font_word : std_logic_vector(7 downto 0);
	signal font_bit : std_logic;
	signal score1_on, score2_on, logo_on, rule_on, over_on, win_on : std_logic;
	signal rule_rom_addr : unsigned(5 downto 0);
	type rule_rom_type is array(0 to 63) of 
			 std_logic_vector(6 downto 0);
	-- rule text ROM definition
	constant RULE_ROM : rule_rom_type :=
	(
		-- row 1
      "1010010", -- R
      "1010101", -- U
      "1001100", -- L
      "1000101", -- E
      "0111010", -- :
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      -- row 2
      "1010101", -- U
      "1110011", -- s
      "1100101", -- e
      "0000000", --
      "1110100", -- t
      "1110111", -- w
      "1101111", -- o
      "0000000", --
      "1100010", -- b
      "1110101", -- u
      "1110100", -- t
      "1110100", -- t
      "1101111", -- o
      "1101110", -- n
      "1110011", -- s
      "0000000", --
      -- row 3
      "1110100", -- t
      "1101111", -- o
      "0000000", --
      "1101101", -- m
      "1101111", -- o
      "1110110", -- v
      "1100101", -- e
      "0000000", --
      "1110000", -- p
      "1100001", -- a
      "1100100", -- d
      "1100100", -- d
      "1101100", -- l
      "1100101", -- e
      "0000000", --
      "0000000", --
      -- row 4
      "1110101", -- u
      "1110000", -- p
      "0000000", --
      "1100001", -- a
      "1101110", -- n
      "1100100", -- d
      "0000000", --
      "1100100", -- d
      "1101111", -- o
      "1110111", -- w
      "1101110", -- n
      "0101110", -- .
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000"  --
	);
begin
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
	--instantiate font rom
	font_unit : entity work.font_rom
		port map(clk => clk, addr => rom_addr, data => font_word);
	
	-- score 1 region
	--   -display score and ballat top left
	--   -text : "Score :DD Ball :D"
	--   -scale to 16 by 32 font
	
	score1_on <= 
		'1'when pix_y(9 downto 5) = 0 and
				  pix_x(9 downto 4) < 16 else
		'0';
	row_addr_s1 <= std_logic_vector(pix_y(4 downto 1));
	bit_addr_s1 <= std_logic_vector(pix_x(3 downto 1));
	with pix_x(7 downto 4) select	
		char_addr_s1 <= 
			"1010011" when "0000",--S
			"1100011" when "0001",--c
			"1101111" when "0010",--o
			"1110010" when "0011",--r
			"1100101" when "0100",--e
			"0111010" when "0101",--:
			"011" & p1_dig1 when "0110",-- digit 10
			"011" & p1_dig0 when "0111",-- digit 1
			"0000000" when "1000",
			"0000000" when "1001",
			"1000010" when "1010",--B
			"1100001" when "1011",--a
			"1101100" when "1100",--l
			"1101100" when "1101",--l
			"0111010" when "1110",--:
			"01100" & ball1 when others;
			
	-- score 2 region
	--   -display score and ballat top left
	--   -text : "Score :DD Ball :D"
	--   -scale to 16 by 32 font
	
	score2_on <= 
		'1'when pix_y(9 downto 5) = 0 and
				  pix_x(9 downto 4) > 23 else
		'0';
	row_addr_s2 <= std_logic_vector(pix_y(4 downto 1));
	bit_addr_s2 <= std_logic_vector(pix_x(3 downto 1));
	with pix_x(7 downto 4) select	
		char_addr_s2 <= 
			"1010011" when "1000",--S
			"1100011" when "1001",--c
			"1101111" when "1010",--o
			"1110010" when "1011",--r
			"1100101" when "1100",--e
			"0111010" when "1101",--:
			"011" & p2_dig1 when "1110",-- digit 10
			"011" & p2_dig0 when "1111",-- digit 1
			"0000000" when "0000",
			"0000000" when "0001",
			"1000010" when "0010",--B
			"1100001" when "0011",--a
			"1101100" when "0100",--l
			"1101100" when "0101",--l
			"0111010" when "0110",--:
			"01100" & ball2 when others;
			
	--logo region:
	-- -display logo "PONG" at top centre
	-- -used as background
	-- -Scale to 64 by 128 font
	
	logo_on <= 
		'1' when pix_y(9 downto 7) = 2 and
			(3 <= pix_x(9 downto 6) and pix_x(9 downto 6) <= 6) else
		'0';
	row_addr_l <= std_logic_vector(pix_y(6 downto 3));
	bit_addr_l <= std_logic_vector(pix_x(5 downto 3));
	with pix_x(8 downto 6) select
		char_addr_l <= 
			"1010000" when "011",--P
			"1001111" when "100",--O
			"1001110" when "101",--N
			"1000111" when others;--G
	
	--rule region
	-- -display rule at centre
	-- -4 lines, ` characters each line
	-- -rule text:
	-- 	Rule:
	--		Use two buttons
	--		to move paddle
	--    up and down
	
	rule_on <= '1' when pix_x(9 downto 7) = "010" and
							  pix_y(9 downto 6) = "0010" else
				  '0';
	row_addr_r <= std_logic_vector(pix_y(3 downto 0));
	bit_addr_r <= std_logic_vector(pix_x(2 downto 0));
	rule_rom_addr <= pix_y(5 downto 4) & pix_x(6 downto 3);
	char_addr_r <= RULE_ROM(to_integer(rule_rom_addr));
	
	-- game over region
	-- -display "Game Over" at center
	-- -scale to 32 by 64 fonts
	
	over_on<= 
		'1' when pix_y(9 downto 6) = 3  and
			5 <= pix_x(9 downto 5) and pix_x(9 downto 5) <= 13 else
			'0';
	row_addr_o <= std_logic_vector(pix_y(5 downto 2));
	bit_addr_o <= std_logic_vector(pix_x(4 downto 2));
	with pix_x(8 downto 5) select	
		char_addr_o <= 
			"1000111" when "0101", --G
			"1100001" when "0110", --a
			"1101101" when "0111", --m
			"1100101" when "1000", --e
			"0000000" when "1001", --
			"1001111" when "1010", --O
			"1110110" when "1011", --v
			"1100101" when "1100", --e
			"1110010" when others; --r
			
	win_on<= 
		'1' when pix_y(9 downto 6) = 6 and
			4 <= pix_x(9 downto 5) and pix_x(9 downto 5) <= 15 else
			'0';
	row_addr_p <= std_logic_vector(pix_y(5 downto 2));
	bit_addr_p <= std_logic_vector(pix_x(4 downto 2));
	with pix_x(8 downto 5) select	
		char_addr_p <= 
			"1010000" when "0100", --P
			"1101100" when "0101", --l
			"1100001" when "0110", --a
			"1111001" when "0111", --y
			"1100101" when "1000", --e
			"1110010" when "1001", --r
			"011" & win_dig when "1010", --X
			"0000000" when "1011", --
			"1010111" when "1100", --W
			"1101001" when "1101", --i
			"1101110" when "1110", --n
			"1110011" when others; --s
	
	--mux for font ROM addresses and rgb
	process(score1_on, score2_on, logo_on, rule_on, pix_x, pix_y, font_bit, over_on,
			  char_addr_s1, char_addr_s2, char_addr_l, char_addr_r, char_addr_o, char_addr_p,
			  row_addr_s1, row_addr_s2, row_addr_l, row_addr_r, row_addr_o, row_addr_p,
			  bit_addr_s1, bit_addr_s2, bit_addr_l, bit_addr_r, bit_addr_o, bit_addr_p)
	begin
		text_rgb <= "000"; -- yellow_background
		if score1_on = '1' then
			char_addr <= char_addr_s1;
			row_addr <= row_addr_s1;
			bit_addr <= bit_addr_s1;
			if font_bit = '1' then
				text_rgb <= "111";
			end if;
		elsif score2_on = '1' then
			char_addr <= char_addr_s2;
			row_addr <= row_addr_s2;
			bit_addr <= bit_addr_s2;
			if font_bit = '1' then
				text_rgb <= "111";
			end if;
		elsif rule_on = '1' then
			char_addr <= char_addr_r;
			row_addr <= row_addr_r;
			bit_addr <= bit_addr_r;
			if font_bit = '1' then
				text_rgb <= "111";
			end if;
		elsif logo_on = '1' then
			char_addr <= char_addr_l;
			row_addr <= row_addr_l;
			bit_addr <= bit_addr_l;
			if font_bit = '1' then
				text_rgb <= "011";
			end if;
		elsif over_on = '1' then
			char_addr <= char_addr_o;
			row_addr <= row_addr_o;
			bit_addr <= bit_addr_o;
			if font_bit = '1' then
				text_rgb <= "110";
			end if;
		else
			char_addr <= char_addr_p;
			row_addr <= row_addr_p;
			bit_addr <= bit_addr_p;
			if font_bit = '1' then
				text_rgb <= "110";
			end if;
		end if;
	end process;
	text_on <= win_on & score1_on & score2_on & logo_on & rule_on & over_on;
	-- font ROM interface
	rom_addr <= char_addr & row_addr;
	font_bit <= font_word(to_integer(unsigned(not bit_addr)));
end arch;