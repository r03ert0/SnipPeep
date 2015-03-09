#ifndef __commonSNP__
#define __commonSNP__

typedef struct
{
	char	name[32];
	float	*r;
	float	*b;
	float	*cn;
}Subject;
typedef struct
{
	float	l;
	float	r;
	float	cn;
	int		n;
}SubjectCN;
typedef struct
{
	char	rs[16];
	float	pos;
}SNP;
#endif