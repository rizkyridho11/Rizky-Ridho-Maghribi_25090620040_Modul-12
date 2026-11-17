library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_driver is
  Port ( clk   : in  STD_LOGIC;
         value : in  STD_LOGIC_VECTOR (15 downto 0);
         seg   : out STD_LOGIC_VECTOR (6 downto 0);   -- seg(6)=CG ... seg(0)=CA
         an    : out STD_LOGIC_VECTOR (3 downto 0) );
end seven_seg_driver;

architecture Behavioral of seven_seg_driver is
  signal refresh : unsigned(17 downto 0) := (others => '0');
  signal sel     : std_logic_vector(1 downto 0);
  signal nibble  : std_logic_vector(3 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      refresh <= refresh + 1;
    end if;
  end process;

  sel <= std_logic_vector(refresh(17 downto 16));

  with sel select
    nibble <= value(3 downto 0)   when "00",
              value(7 downto 4)   when "01",
              value(11 downto 8)  when "10",
              value(15 downto 12) when others;

  with sel select
    an <= "1110" when "00",
          "1101" when "01",
          "1011" when "10",
          "0111" when others;

  with nibble select
    seg <= "1000000" when x"0",
           "1111001" when x"1",
           "0100100" when x"2",
           "0110000" when x"3",
           "0011001" when x"4",
           "0010010" when x"5",
           "0000010" when x"6",
           "1111000" when x"7",
           "0000000" when x"8",
           "0010000" when x"9",
           "0001000" when x"A",
           "0000011" when x"B",
           "1000110" when x"C",
           "0100001" when x"D",
           "0000110" when x"E",
           "0001110" when others;
end Behavioral;