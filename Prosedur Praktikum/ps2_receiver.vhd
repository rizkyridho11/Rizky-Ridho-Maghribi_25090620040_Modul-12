library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ps2_receiver is
  Port ( clk        : in  STD_LOGIC;                       -- 100 MHz
         ps2_clk    : in  STD_LOGIC;
         ps2_data   : in  STD_LOGIC;
         scan_code  : out STD_LOGIC_VECTOR (7 downto 0);
         data_ready : out STD_LOGIC );                     -- pulsa 1 siklus
end ps2_receiver;

architecture Behavioral of ps2_receiver is
  signal clk_ff1, clk_ff2, clk_ff3 : STD_LOGIC := '1';
  signal data_ff1, data_ff2        : STD_LOGIC := '1';
  signal ps2_fall                  : STD_LOGIC;
  signal shift_reg : STD_LOGIC_VECTOR (10 downto 0) := (others => '1');
  signal bit_cnt   : integer range 0 to 10 := 0;
  signal timeout   : integer range 0 to 10000 := 0;
  signal code_reg  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

  -- odd parity: jumlah '1' pada 8 bit data + bit parity harus ganjil
  function odd_parity_ok(f : STD_LOGIC_VECTOR(10 downto 0)) return boolean is
    variable p : STD_LOGIC := '0';
  begin
    for i in 1 to 9 loop
      p := p xor f(i);
    end loop;
    return p = '1';
  end function;
begin
  -- Sinkronisasi
  process(clk)
  begin
    if rising_edge(clk) then
      clk_ff1 <= ps2_clk; clk_ff2 <= clk_ff1; clk_ff3 <= clk_ff2;
      data_ff1 <= ps2_data; data_ff2 <= data_ff1;
    end if;
  end process;

  ps2_fall <= clk_ff3 and not clk_ff2;   -- tepi turun ps2_clk

  -- Penerima frame 11 bit
  process(clk)
    variable frame : STD_LOGIC_VECTOR (10 downto 0);
  begin
    if rising_edge(clk) then
      data_ready <= '0';
      if ps2_fall = '1' then
        timeout <= 0;
        frame := shift_reg;
        frame(bit_cnt) := data_ff2;
        shift_reg <= frame;
        if bit_cnt = 10 then
          bit_cnt <= 0;
          -- (0)=start, (8 downto 1)=data LSB..MSB, (9)=parity, (10)=stop
          if frame(0) = '0' and frame(10) = '1' and odd_parity_ok(frame) then
            code_reg   <= frame(8 downto 1);
            data_ready <= '1';
          end if;
        else
          bit_cnt <= bit_cnt + 1;
        end if;
      elsif timeout = 10000 then
        bit_cnt <= 0;                    -- frame terputus: mulai ulang
      else
        timeout <= timeout + 1;
      end if;
    end if;
  end process;

  scan_code <= code_reg;
end Behavioral;