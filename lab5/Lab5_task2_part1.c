#define LED ((volatile long *) 0xFF200000)
#define PUSHBUTTONS ((volatile long *) 0xFF200050)

int main() {

    while (1) {
		*LED = *PUSHBUTTONS;
    }
    
    return 0;
}