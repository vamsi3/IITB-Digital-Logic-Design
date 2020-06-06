----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    05:12:16 01/23/2018 
-- Design Name: 
-- Module Name:    encrypter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity encrypter is
	Port (	clock : in STD_LOGIC;
			K : in STD_LOGIC_VECTOR(31 downto 0);
			P : in STD_LOGIC_VECTOR(31 downto 0);
			C : out STD_LOGIC_VECTOR(31 downto 0);
			done : out STD_LOGIC;
			reset : in STD_LOGIC;
			enable : in STD_LOGIC);
end encrypter;

architecture Behavioral of encrypter is

signal tempC: STD_LOGIC_VECTOR(31 downto 0):= (others => '0');
signal T: STD_LOGIC_VECTOR(3 downto 0):= (others => '0');
signal i: INTEGER:= -1; -- since there is an initialisation step before the for loop
begin

   process(clock, reset, enable)
	begin
		if (reset = '1') then
			-- Reset condition
			done <= '0';
			tempC <= (others => '0');
			C <= (others => '0');
			T <= (others => '0');
			i <= -1;
		elsif (clock'event and clock = '1') then 
			if (enable = '1' and i /= 33) then
				if (i = -1) then
					-- Initialisation step
					tempC <= P;
					T(3) <= K(31) XOR K(27) XOR K(23) XOR K(19) XOR K(15) XOR K(11) XOR K(7) XOR K(3);
					T(2) <= K(30) XOR K(26) XOR K(22) XOR K(18) XOR K(14) XOR K(10) XOR K(6) XOR K(2);
					T(1) <= K(29) XOR K(25) XOR K(21) XOR K(17) XOR K(13) XOR K(9) XOR K(5) XOR K(1);
					T(0) <= K(28) XOR K(24) XOR K(20) XOR K(16) XOR K(12) XOR K(8) XOR K(4) XOR K(0);
				elsif (i = 32) then
					done <= '1';
					C <= tempC;
				elsif (K(i) = '1') then
					-- The for loop
					tempC <= tempC XOR T&T&T&T&T&T&T&T;
					T <= T + "0001";
				end if;
				i <= i+1;
			end if;
		end if;	
	end process;

end Behavioral;
