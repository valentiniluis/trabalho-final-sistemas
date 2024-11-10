library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity blackjack is
    port(
        clk : in std_logic;
        hit, stay, start : in std_logic;
        cards : in std_logic_vector(3 downto 0);
        
        win, lose, tie : out std_logic;
        sum_player, sum_dealer : out std_logic_vector(4 downto 0)

    );
end blackjack;

architecture behav of blackjack is
    signal soma_player, soma_dealer, as_player, as_dealer : integer := 0;
    signal game_over : std_logic;
    signal inicio_jogo : std_logic := '1';

    type estado is (inicio, nova_carta_player, nova_carta_dealer, escolha_player, escolha_dealer, decidir_vencedor, empatou, perdeu, venceu);

    signal estado_atual : estado;

begin

    process(clk, start)
    variable aux_soma_player : integer := soma_player;
    variable aux_soma_dealer : integer := soma_dealer;
    variable aux_as_player : integer := as_player;
    variable aux_as_dealer : integer := as_dealer;
    begin

        if (start='1') then
            estado_atual <= inicio;
            inicio_jogo <= '1';
            game_over <= '0';
            soma_player <= 0;
            soma_dealer <= 0;
            aux_as_dealer := 0;
            aux_as_player := 0;
            aux_soma_dealer := 0;
            aux_soma_player := 0;
            win <= '0';
            lose <= '0';
            tie <= '0';

        elsif (clk'event and clk='1' and game_over='0') then
            case estado_atual is
                when inicio =>
                        estado_atual <= nova_carta_player;

                when nova_carta_player =>

                    if (cards="0001") then
                        aux_soma_player := soma_player + 11;
                        aux_as_player := aux_as_player + 1;
                    elsif (cards="1011" or cards="1100" or cards="1101") then
                        aux_soma_player := soma_player + 10;
                    else
                        aux_soma_player := soma_player + to_integer(unsigned(cards));
                    end if;

                    if (aux_soma_player>21 and aux_as_player>0) then
                        aux_soma_player := aux_soma_player - 10;
                        aux_as_player := aux_as_player - 1;
                    end if;

                    soma_player <= aux_soma_player;
                    as_player <= aux_as_player;

                    if (inicio_jogo='1') then
                        estado_atual <= nova_carta_dealer;
                    else
                        estado_atual <= escolha_player;
                    end if;
                
                when nova_carta_dealer =>

                    if (cards="0001") then
                        aux_soma_dealer := soma_dealer + 11;
                        aux_as_dealer := aux_as_dealer + 1;
                    elsif (cards="1011" or cards="1100" or cards="1101") then
                        aux_soma_dealer := soma_dealer + 10;
                    else
                        aux_soma_dealer := soma_dealer + to_integer(unsigned(cards));
                    end if;

                    if (aux_soma_dealer>21 and aux_as_dealer>0) then
                        aux_soma_dealer := aux_soma_dealer - 10;
                        aux_as_dealer := aux_as_dealer - 1;
                    end if;

                    soma_dealer <= aux_soma_dealer;
                    as_dealer <= aux_as_dealer;
                    
                    if (inicio_jogo='0') then
                        estado_atual <= escolha_dealer;
                    elsif (soma_dealer>0) then
                        inicio_jogo <= '0';
                        estado_atual <= escolha_player;
                    else
                        estado_atual <= nova_carta_player;
                    end if;

                when escolha_player =>
                    if (hit='1' and stay='0') then
                        estado_atual <= nova_carta_player;
                    elsif (hit='0' and stay='1') then
                        estado_atual <= escolha_dealer;
                    end if;

                when escolha_dealer => 
                    if (soma_dealer>=17) then
                        estado_atual <= decidir_vencedor;
                    else
                        estado_atual <= nova_carta_dealer;
                    end if;

                when decidir_vencedor =>
                    if (soma_player>soma_dealer) then
                        estado_atual <= venceu;
                    elsif (soma_player=soma_dealer) then
                        estado_atual <= empatou;
                    else
                        estado_atual <= perdeu;
                    end if;
                    
                when others =>
                    game_over <= '1';

            end case;
        end if;

        if (aux_soma_player=21 or (aux_soma_dealer>21 and aux_as_dealer=0)) then
            win <= '1';
            estado_atual <= venceu;
            game_over <= '1';

        elsif (aux_soma_dealer=21 or (aux_soma_player>21 and aux_as_player=0)) then
            lose <= '1';
            estado_atual <= perdeu;
            game_over <= '1';

        elsif (estado_atual=decidir_vencedor) then
            if (aux_soma_player>aux_soma_dealer) then
                win <= '1';
            elsif (aux_soma_dealer>aux_soma_player) then
                lose <= '1';
            else
                tie <= '1';
            end if;
            game_over <= '1';
        end if;


    end process;

    update_Sums : process(soma_dealer, soma_player)
    begin

        sum_dealer <= std_logic_vector(to_unsigned(soma_dealer, sum_dealer'length));
        sum_player <= std_logic_vector(to_unsigned(soma_player, sum_player'length));

    end process;

end behav;