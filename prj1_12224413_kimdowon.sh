# Error messege
if [ $# -lt 3 ] || ! [ -f "/home/dowon/Downloads/$1" ] || ! [ -f "/home/dowon/Downloads/$2" ] || ! [ -f "/home/dowon/Downloads/$3" ]; then
    echo "usage: ./2024-OSS-Project1.sh teams.csv players.csv matches.csv"
    exit 1
fi

# csv Variable 
teams_csv="/home/dowon/Downloads/$1"
players_csv="/home/dowon/Downloads/$2"
matches_csv="/home/dowon/Downloads/$3"

# Whoami
echo "************OSS1 - Project1***********"
echo "*       StudentID : 12224413         *"
echo "*       Name : Dowon Kim             *"
echo "**************************************"
echo

# Repeat untill 7
while true; do
    echo
    echo "[MENU]"
    echo "1. Get the data of Heung-Min Son's Current Club, Appearances, Goals, Assists in players.csv"
    echo "2. Get the team data to enter a league position in teams.csv"
    echo "3. Get the Top-3 Attendance matches in matches.csv"
    echo "4. Get the team's league position and team's top scorer in teams.csv & players.csv"
    echo "5. Get the modified format of date_GMT in matches.csv"
    echo "6. Get the data of the winning team by the largest difference on home stadium in teams.csv & matches.csv"
    echo "7. Exit"
    echo -n "Enter your CHOICE (1~7) : "
    read choice

    case $choice in
        1)
            read -p "Do you want to get the Heung-Min Son's data? (y/n) : " yn
            if [ "$yn" = "y" ]; then
                awk -F, '$1 == "Heung-Min Son" {print "Team:"$4",Appearance:"$6",Goal:"$7",Assist:"$8}' $players_csv
            fi
            ;;
        2)
            read -p "What do you want to get the team data of league_position[1~20] : " league_position
            if [[ $league_position =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
                awk -F, -v league_position="$league_position" '$6 == league_position {printf "%d %s %.6f\n", $6, $1, $2/($2+$3+$4)}' $teams_csv
            else
                echo "Invalid input. Please enter a number between 1 and 20."
            fi
            ;;
        3)
            read -p "Do you want to know Top-3 attendance data? (y/n) : " yn
            if [ "$yn" = "y" ]; then
                echo "***Top-3 Attendance Match***"
		echo
                sort -t, -k2nr "$matches_csv" | awk -F, 'NR<=3 {print $3" vs "$4" ("$1")\n"$7 "\n"}'
            fi
            ;;
        4)
  read -p "Do you want to get each team's ranking and the highest-scoring player? (y/n) : " yn
  if [ "$yn" = "y" ]; then
    declare -A team_ranks
    declare -A top_scorer
    declare -A top_scorer_goals
    echo

    # Team name, League ranking
    while IFS=, read -r team_name _ _ _ _ league_position _; do
      team_ranks["$team_name"]=$league_position
    done < <(tail -n +2 "$teams_csv") 

    # Top_scorer
    while IFS=, read -r full_name _ _ club _ _ goals _; do
      if [[ "$club" != "Current Club" ]]; then
        if [[ -z "${top_scorer[$club]}" ]] || [[ "$goals" -gt "${top_scorer_goals[$club]}" ]]; then
          top_scorer[$club]="$full_name"
          top_scorer_goals[$club]="$goals"
        fi
      fi
    done < "$players_csv"

    # Print
    for team_name in "${!team_ranks[@]}"; do
	    team_rank=${team_ranks[$team_name]}
	    player_name="${top_scorer[$team_name]}"
	    goals="${top_scorer_goals[$team_name]}"
	    echo -e "$team_rank $team_name\t$player_name $goals"
    done | sort -nk1,1 | awk -F'\t' '{print $1 " " $2; print $3 " " $4}'
    fi
    ;;
        5)
  read -p "Do you want to modify the format of date? (y/n) : " yn
  if [ "$yn" = "y" ]; then
     sed -n '2,11p' "$matches_csv" | sed -E 's/([A-Za-z]{3}) ([0-9]{1,2}) ([0-9]{4}) - ([0-9]{1,2}:[0-9]{2}(am|pm)).*/\3\/\1\/\2 \4/' | sed -E 's/Jan/01/; s/Feb/02/; s/Mar/03/; s/Apr/04/; s/May/05/; s/Jun/06/; s/Jul/07/; s/Aug/08/; s/Sep/09/; s/Oct/10/; s/Nov/11/; s/Dec/12/'
  fi
  ;;
         
        6)
  awk -F, 'NR>1 {print NR-1 ") " $1}' "$teams_csv"
  read -p "Enter your team number : " team_num
  echo
  team_name=$(awk -F, -v team_num="$team_num" 'NR==team_num+1 {print $1}' "$teams_csv")

    home_wins=$(sed -n '2,$p' "$matches_csv" | awk -F, -v team_name="$team_name" '$3 == team_name && $5 > $6 {print $5-$6}' )
    max_diff=0
    for diff in $home_wins; do
      if [ "$diff" -gt "$max_diff" ]; then 
        max_diff="$diff"
      fi
    done

    sed -n '2,$p' "$matches_csv" | awk -F, -v team_name="$team_name" -v max_diff="$max_diff" '$3 == team_name && $5-$6 == max_diff {print $1 "-" $2 "\n" team_name, $5, "vs", $6, $4 "\n"}' | sed -E 's/([A-Za-z]{3} [0-9]{2} [0-9]{4}) - ([0-9]{1,2}:[0-9]{2}(am|pm))/\1 - \2/' 
  ;;
        7)
            echo "Bye!"
            exit 0
            ;;
    esac
done
