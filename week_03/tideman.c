#include <cs50.h>
#include <stdio.h>
#include <string.h>
// Max number of candidates
#define MAX 9

// preferences[i][j] is number of voters who prefer i over j
int preferences[MAX][MAX];

// locked[i][j] means i is locked in over j
bool locked[MAX][MAX];

// Each pair has a winner, loser
typedef struct
{
    int winner;
    int loser;
}
pair;

// Array of candidates
string candidates[MAX];
pair pairs[MAX * (MAX - 1) / 2];

int pair_count;
int candidate_count;

// Function prototypes
bool vote(int rank, string name, int ranks[]);
void record_preferences(int ranks[]);
void add_pairs(void);
void sort_pairs(void);
void lock_pairs(void);
void print_winner(void);

int main(int argc, string argv[])
{
    // Check for invalid usage
    if (argc < 2)
    {
        printf("Usage: tideman [candidate ...]\n");
        return 1;
    }

    // Populate array of candidates
    candidate_count = argc - 1;
    if (candidate_count > MAX)
    {
        printf("Maximum number of candidates is %i\n", MAX);
        return 2;
    }
    for (int i = 0; i < candidate_count; i++)
    {
        candidates[i] = argv[i + 1];
    }

    // Clear graph of locked in pairs
    for (int i = 0; i < candidate_count; i++)
    {
        for (int j = 0; j < candidate_count; j++)
        {
            locked[i][j] = false;
        }
    }

    pair_count = 0;
    int voter_count = get_int("Number of voters: ");

    // Query for votes
    for (int i = 0; i < voter_count; i++)
    {
        // ranks[i] is voter's ith preference
        int ranks[candidate_count];

        // Query for each rank
        for (int j = 0; j < candidate_count; j++)
        {
            string name = get_string("Rank %i: ", j + 1);

            if (!vote(j, name, ranks))
            {
                printf("Invalid vote.\n");
                return 3;
            }
        }

        record_preferences(ranks);

        printf("\n");
    }

    add_pairs();
    sort_pairs();
    lock_pairs();
    print_winner();
    return 0;
    // Why?
}

// Update ranks given a new vote
bool vote(int rank, string name, int ranks[])
{
    for (int i = 0; i < candidate_count; i++)
    {
        if (strcoll(name, candidates[i]) == 0)
        {
            ranks[rank] = i;
            return true;
            break;
        }
    }
    return false;
}


// Update preferences given one voter's ranks
void record_preferences(int ranks[])
{
    for (int i = 0; i < candidate_count-1; i++)
    {
        for (int j = i+1; j < candidate_count; j++)
        {
            preferences[ranks[i]][ranks[j]]++;
        }
    }

}

// Record pairs of candidates where one is preferred over the other
void add_pairs(void)
{
    for (int i = 0; i < candidate_count; i++)
    {
        for (int j = 0; j < candidate_count; j++)
        {
            if (preferences[i][j] > preferences[j][i] && j != i)
            {
                pairs[pair_count].winner = i;
                pairs[pair_count].loser = j;
                pair_count++;
            }
        }
    }
}

// Sort pairs in decreasing order by strength of victory
void sort_pairs(void)
{
    int swaps = 10;
    while (swaps != 0)
    {
        swaps = 0;
        for (int i = 0; i < pair_count-1; i++)
        {
            int s = preferences[pairs[i].winner][pairs[i].loser] - preferences[pairs[i].loser][pairs[i].winner];
            int sp = preferences[pairs[i+1].winner][pairs[i+1].loser] - preferences[pairs[i+1].loser][pairs[i+1].winner];
            if (s < sp)
            {
                pair temp = pairs[i];
                pairs[i] = pairs[i+1];
                pairs[i+1] = temp;
                swaps++;
            }
        }
    }
    return;
}

// Lock pairs into the candidate graph in order, without creating cycles
void lock_pairs(void)
{
    for (int i = 0; i < pair_count; i++)
    {
        bool statement = true;
        bool cicl = false;
        /*int up;
        int down;*/
        for (int j = 0; j < pair_count; j++)
        {
            for (int d = 1; d < pair_count; d++)
            {
                if (locked[pairs[i-d].winner][pairs[i].winner])
                {
                    for (int e = 0; e < pair_count; e++)
                    {
                        if (locked[pairs[i-e].winner][pairs[i-d].winner] && locked[pairs[i].loser][pairs[i-e].winner])
                        {
                            cicl = true;
                        }
                        else if (locked[pairs[i].loser][pairs[i-d].winner])
                        {
                            cicl = true;
                        }
                    }
                }
            }
            if (locked[j][pairs[i].winner] && !locked[j][pairs[i].loser] && cicl)
            {
                if (locked[pairs[i].loser][j])
                {
                    statement = false;
                }
            }
        }
        if (statement)
        {
            locked[pairs[i].winner][pairs[i].loser] = true;
        }
    }
    return;
}
// Print the winner of the election
void print_winner(void)
{
    string winner;
    for (int i = 0; i < candidate_count; i++)
    {
        bool statement = true;
        for (int j = 0; j < candidate_count; j++)
        {
            if (locked[j][i])
            {
                statement = false;
            }
        }
        if (statement)
        {
            winner = candidates[i];
        }
    }
    printf("%s\n", winner);
    return;
}
