int x, y, z;
float f;

int add(int a, int b){
	return a+b;
}

int add(int a){
	return a;
}

int bad(int a, int a){
	return a;
}

void show(int a){
	y = a;
}

int main(){
	int p, q, arr[5];
	void v;
	float p;

	p = 1;
	q = add(p, q);
	q = add(p);

	arr[0] = 3;
	arr[1.5] = 4;
	p[2] = 5;
	arr = 6;

	undeclared = 7;
	q = missing(p);

	printf(unknown);
	return 0;
}
