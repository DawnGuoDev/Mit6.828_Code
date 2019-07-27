int  bar(int c, int d){
	int e = c + d;
	return e;

}

int foo(int a, int b){
	return bar(a, b);
}

int main(){
	foo(1, 2);
	return 0;
}

