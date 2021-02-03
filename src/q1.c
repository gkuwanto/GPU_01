/* 1.1

Creates an integer pointer, sets the value to which it points to 3, adds 2 to
this value, and prints said value. */

void test1() {
    // When declaring a pointer, = is for a point in memory, not the value
    int *a = (int *)malloc(sizeof(int));
    *a = 3;
    *a = *a + 2;
    printf("%d\n", *a);
}


/* 1.2

Creates two integer pointers and sets the values to which they point to 2 and 3,
respectively. */

void test2() {
    int *a, *b; //When declaring a pointer, each variable needs the * before it.
    a = (int *) malloc(sizeof (int));
    b = (int *) malloc(sizeof (int));

    if (!(a && b)) {
        printf("Out of memory\n");
        exit(-1);
    }
    *a = 2;
    *b = 3;
}


/* 1.3

Allocates an array of 1000 integers, and for i = 0, ..., 999, sets the i-th
element to i. */

void test3() {
    // 1000 is not for the number of elements, but the size
    int i, *a = (int *) malloc(1000*sizeof(int));

    if (!a) {
        printf("Out of memory\n");
        exit(-1);
    }
    for (i = 0; i < 1000; i++)
        *(i + a) = i;
}


/* 1.4

Creates a two-dimensional array of size 3x100, and sets element (1,1) (counting
from 0) to 5. */

void test4() {
    int **a = (int **) malloc(3 * sizeof (int *));
    // need to allocate memory for each row
    for (int i = 0; i<3; i++)
        a[i] = (int *) malloc(100 * sizeof(int));
    a[1][1] = 5;
}


/* 1.5

Sets the value pointed to by a to an input, checks if the value pointed to by a
is 0, and prints a message if it is. */

void test5() {
    int *a = (int *) malloc(sizeof (int));
    scanf("%d", a);
    if (!*a) // was checking the pointer not the value
        printf("Value is 0\n");
}
