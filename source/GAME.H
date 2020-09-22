/***
 *			General Header file for Nuclear Rush
 *				Copyright 1993, Futurescape Productions
 *				All Rights Reserved
 ***/

/***
 *		Useful typedefs, macros, and assembly language functions
 ***/

typedef unsigned char	BYTE;
typedef short				WORD;
typedef unsigned short	UWORD;
typedef long				LONG;
typedef unsigned long	ULONG;

#ifndef NULL
#define	NULL		0
#endif

#define	FALSE		0
#define	TRUE		~FALSE

#define	MOV3D				(INT2FRAC(3) >> 2)
#define	BULTS_MOV3D		(INT2FRAC(1) >> 1)


/***** Externals ********/
extern BYTE VdpShadow[24];

/****** Prototypes ******/
extern void SegaLogo(void);
extern void SetSR(UWORD sr);
extern void	SYS_DMA(ULONG video_addr,ULONG length,ULONG *src_addr);
extern void	SYS_SetVAddr(ULONG video_addr);
extern void	SYS_SetPalette(UWORD *pal_addr);
extern void	SYS_SendPalette();
extern void	SYS_ClrPalette();
extern void	SYS_FadeIn(ULONG frames);
extern void	SYS_FadeOut(ULONG frames);
extern void SYS_WaitFrame();
extern volatile BYTE	SYS_JoyTable[16];
extern volatile BYTE	SYS_Joy2Table[16];
extern volatile ULONG	SYS_JoyHit;
extern void	EHInts();
extern void SYS_DCListHold();
extern void SYS_DCListGo();
extern void SYS_DCAddVAddr(UWORD Value);
extern void SYS_DCAddData(UWORD Value);

extern void	LZ_Open(BYTE *comp_data,BYTE *ring_buffer);
extern void	LZ_Read(BYTE *buffer,ULONG num_bytes);
extern void	LZ_Seek(ULONG pos);

#define	DisableInts()	asm(" move.w #$2700,SR");
#define	EnableInts()	asm(" move.w #$2000,SR");

#define	SpriteAttr	0xB400

#define	JOY_UP		0x0
#define	JOY_DOWN		0x2
#define	JOY_LEFT		0x4
#define	JOY_RIGHT	0x6
#define	JOY_B			0x8
#define	JOY_C			0xA
#define	JOY_A			0xC
#define	JOY_START	0xE

/**** MACROS *****/
#define EXT_DATA		(*((BYTE *)0xA10007))
#define EXT_CTRL		(*((BYTE *)0xA1000D))
#define VDATA			(*((UWORD *)0xC00000))
#define VCTRL			(*((ULONG *)0xC00004))
#define WVCTRL			(*((UWORD *)0xC00004))
#define VCNTR			(*((UWORD *)0xC00008))

/** Set vdp register macro has mondo side effects! **/
#define SetVdpRegister(reg,val) *((UWORD *)0xC00004)=0x8000|((reg<<8)|val);VdpShadow[reg]=val

/***
 *			Fractional Math definitions
 ***/

typedef LONG	FRAC;

#define	FRACSIZE	16
#define	FRACPOW	65536
#define	FRACMASK	0xFFFFl
#define	INT2FRAC(x)	(((FRAC)(x))<<FRACSIZE)
#define	FRAC2INT(x)	((int)((x)>>FRACSIZE))
#define	FLOAT2FRAC(x)	((FRAC)(x*FRACPOW))

extern	FRAC	fmul(FRAC a,FRAC b);					/* Multiply */
extern	FRAC	fsmul(FRAC a,FRAC b);				/* Special Multiply */
extern	FRAC	fdiv(FRAC a,FRAC b);					/* Divide */
extern	FRAC	frec(FRAC a);							/* Receprical */
extern	int	fround(FRAC x);						/* Round */
extern	FRAC	fsind(int Angle);						/* Sine */
extern	FRAC	fcosd(int Angle);						/* Cosine */
extern	FRAC	ftan(int Angle);						/* Tangent */
extern	int	fatan2(FRAC x,FRAC y);				/* Arctangent */
extern	FRAC	fdist3d(FRAC x,FRAC y,FRAC z);	/* Distance from origin */
extern	WORD	dist2d(WORD x1,WORD y1,WORD x2,WORD y2);	/* 2D distance */
extern	WORD	PntOnCirc(WORD xp,WORD yp,WORD xc,WORD yc,WORD r);

/* Maximum number of drones in the world, add to MAX3DOBJS */

#define	NUMDRONS			20
#define	NUMBULTS			20
#define	NUMMINES			6
#define	NUMTANKS			20

#define	MAX3DOBJS		300+NUMDRONS+NUMBULTS+NUMMINES+NUMTANKS
#define	WORLD_WIDTH		INT2FRAC(2048)
#define	WORLD_DEPTH		INT2FRAC(2048)

/***
 *		OBJECT3D is the main structure for 3D objects.  It has all the
 *		elements needed to calculate screen positions and world positions.
 *
 *		A flag called "special" will make the 3D viewing routine call the
 *		function pointed to by "spc_func" and will use datum set up by that
 *		function to draw new dynamic objects.  This allows for animated
 *		objects to be viewed only when on the visable screen, such as
 *		explosions.  Objects can also have daughter objects that float near
 *		or above the main object.  Or the function could simply set flags
 *		when being targeted.
 *
 *		See 3D.C68 for the variable that allows new 3D objects to be passed
 *		back to the rendering routine.
 *
 *		"spc_func" needs to return a WORD.  If this word is 0 it won't be
 *		called again, but if it is something else it will be called until
 *		a 0 is returned.  This allows for as many objects to be rendered
 *		with a main object as needed.  For example, an explosion may need
 *		several 3D metal chunks flying off in different directions.
 *
 *		"variable" is cleared when added to the world.
 *
 ***/

#define	PT_GRND		0
#define	PT_DRONE		1
#define	PT_TANK		2
#define	PT_MINE		3
#define	PT_MISSILE	4
#define	PT_POOL	5

typedef struct obj3d {
	FRAC				x;				/* World Position, X Y and Z */
	FRAC				y;
	FRAC				z;
	WORD				rotation;	/* Current object rotation */
	UWORD				tilt;			/* Current object tilt */
	UWORD				scaler;		/* Scaler for this object */
	const UWORD		*file;		/* Pointer to FPA animation "file" */
	WORD				type;			/* The type of parent object */
	void				*parent;		/* Pointer to parent structure */
	UWORD				area;			/* Zone (0-63) of current location */
	struct obj3d	*prev;		/* Pointer to previous in linked list */
	struct obj3d	*next;		/* Pointer to next in linked list */
	WORD				(*spc_func)();	/* See above */
	WORD				variable;	/* For special function */
	BYTE				anim;			/* Currently displayed animation in file */
	BYTE				frame;		/* Currently displayed frame in animation */
	UWORD				clipped:1,	/* Clipped flag */
						noscale:1,	/* Not a Scaled object flag */
						cloaked:1,	/* Do not display a cloaked object */
						flag32:1,	/* 32 degrees of rotation */
						norot:1,		/* Don't compute any rotations for object */
						notilt:1,	/* Don't compute tilt for object */
						special:1;	/* Flag for special 3D rendering */
} OBJECT3D;

extern void	SYS_Copy3DObj(OBJECT3D *dest, OBJECT3D *src);

/***
 *		VISABLE3D is a structure for all the visable screen objects
 *		This cuts memory waste and allows more flexability in OBJECT3D
 ***/

typedef struct {
	OBJECT3D			*object;		/* Pointer to real 3D object */
	FRAC				dist;			/* Distance from camera */
	UWORD				scale;		/* Current object scale */
	WORD				xs;			/* X Screen co-ordinates */
	WORD				ys;			/* Y Screen co-ordinates */
	WORD				center_y;	/* For cross-hairs */
	const UWORD		*file;		/* Pointer to FPA animation "file" */
	BYTE				anim;			/* Currently displayed animation in file */
	BYTE				frame;		/* Currently displayed frame in animation */
	WORD				type;			/* The type of parent object */
	void				*parent;		/* Pointer to parent structure */
	UWORD				special:1;	/* Flag for special 3D rendering */
} VISABLE3D;

extern void	SYS_CopyV3DObj(VISABLE3D *dest, VISABLE3D *src);

extern void Init3D();
extern void Move3D(int Ang, int Tlt,FRAC x, FRAC y, FRAC z);
extern OBJECT3D *Add3DObject(UWORD *file, FRAC x, FRAC y, FRAC z);
extern void View3DObjects(int left);
extern void Update3DObject(OBJECT3D *ptr);

typedef struct {
	OBJECT3D			*world_obj;	/* World 3D data */
	OBJECT3D			*can_obj;	/* World 3D data for Canister */
	UWORD				level;		/* Current level of radiation */
	UWORD				owner;		/* Who owns this radiation pool? */
	UWORD				rcr_level;	/* Current RCR drain level */
	BYTE				can_frm;		/* Canister frame count */
	BYTE				can_dir;		/* Canister direction, up or down */
	BYTE				anm_state;	/* For "Animate_Can" */
	UWORD				free:1,		/* Nuke pool has no owner */
						ready:1,		/* Canister floating */
						dead:1,		/* Nuke pool is dry or blown up */
						loiter:1;	/* Nuke pool has a loiterer */
} NUKE_POOL;

/***		Player_Fuel is seperate since it is used in VBlank

extern WORD		Player_Fuel;

 ***/

typedef struct {
	FRAC	X;				/* X world position of player */
	FRAC	Y;				/* Y world position of player */
	FRAC	Z;				/* Z world position of player */
	WORD	Rotation;	/* Direction player is looking */
	WORD	Tilt;			/* Tilt angle player is looking */
	FRAC	Thrust;		/* Ship thrust as derived from the joystick */
	WORD	Gieger;
	WORD	Items[7];
	WORD	Credits;
	WORD	Won;			/* Finished level! */
	WORD	Rest;			/* Don't attack the player for n frames */
	WORD	Damage;
	WORD	Missiles;	/* Number of missiles */
} PLAYER;

extern void	Hit_Player(WORD damage);

typedef struct {
	OBJECT3D	*Obj;			/* Enemy Drone 3D object number */
	OBJECT3D	*Target;		/* Enemy drone targets */
	FRAC		Thrust;		/* Drone Thrust */
	ULONG		Map1;			/* Map of explored areas */
	ULONG		Map2;			/* Map of explored areas */
	WORD		HitPoints;	/* Amount of damage taken before destroyed */
	WORD		DroneType;	/* Which type of drone is it? */
	UWORD		flying:1,		/* Drone is alive and flying */
				GotzAGoal:1,	/* Tracking something */
				AtakPlyr:1,		/* Track player */
				Loiter:1,		/* Hang around RCR */
				Stealth:1,		/* Stealth, cloaking */
				Visable:1,		/* Drone is visable to the player */
		  		explode:1;		/* Drone is exploding */
} DRONE;

typedef struct crack {
	int				x;				/* Screen Position X Y */
	int				y;
	BYTE				frame;		/* Currently displayed frame in animation */
} CRACKLIST;

extern void	PDQS_New(void );
extern void	PDQS_Init(void );

/***
 *		External Art files:
 ***/

extern	UWORD	hud_map;
extern	UWORD	backgrnd_map;
extern	UWORD	nukelogo_map;
extern	UWORD	cockpit_map;
extern	UWORD	enhance_map;
extern	UWORD hud_map;
extern	UWORD cockpit_map;
extern	UWORD nukeruin_map;
extern	UWORD droncrsh_map;
extern	UWORD punk1_map;
extern	UWORD punk2_map;
extern	UWORD gooderth_map;
extern	UWORD uglyerth_map;
extern	UWORD map_map;
extern	UWORD fp_logo_map;

extern	UWORD	desert_map;
extern	UWORD	midwest_map;
extern	UWORD	ice_map;
extern	UWORD	forest_map;
extern	UWORD	froznlab_map;
extern	UWORD	ocean_map;
extern	UWORD	vegas_map;
extern	UWORD	flatcity_map;

extern	UWORD	disolve_anm;
extern	UWORD	infrared_anm;
extern	UWORD	lasergun_anm;
extern	UWORD	oozemap_anm;
extern	UWORD	shield_anm;
extern	UWORD	engine_anm;
extern	UWORD	player_anm;
extern	UWORD	cloak_anm;
extern	UWORD	forcefld_anm;
extern	UWORD hud_art_anm;
extern	UWORD compass_anm;
extern	UWORD cracks_anm;
extern	UWORD llazer_anm;
extern	UWORD rlazer_anm;
extern	UWORD missles_anm;

extern	UWORD	cactus_fpb;
extern	UWORD	joshua_fpb;
extern	UWORD	pear_fpb;
extern	UWORD	sagebush_fpb;
extern	UWORD	grass_fpb;
extern	UWORD	maple_fpb;
extern	UWORD	oak_fpb;
extern	UWORD	rock_fpb;
extern	UWORD	sealbone_fpb;
extern	UWORD	tombston_fpb;
extern	UWORD	wellruin_fpb;
extern	UWORD	igloo32_fpb;
extern	UWORD	jeep_fpb;
extern	UWORD	explode_fpb;
extern	UWORD	pool_fpb;
extern	UWORD	zoomer32_fpb;
extern	UWORD	can32_fpb;
extern	UWORD	fed32_fpb;
extern	UWORD	gramps32_fpb;
extern	UWORD	mine32_fpb;
extern	UWORD	missle32_fpb;
extern	UWORD	mod32_fpb;
extern	UWORD	rcr32_fpb;
extern	UWORD drift1_fpb;
extern	UWORD drift2_fpb;
extern	UWORD drift3_fpb;
extern	UWORD drift4_fpb;
extern	UWORD house32_fpb;
extern	UWORD tank32_fpb;
extern	UWORD zzap_fpb;
extern	UWORD	piece1_fpb;
extern	UWORD	piece2_fpb;
extern	UWORD	piece3_fpb;
extern	UWORD	piece4_fpb;
extern	UWORD	piece5_fpb;
extern	UWORD	piece6_fpb;
extern	UWORD nukebomb_fpb;
extern	UWORD buoy1_fpb;
extern	UWORD buoy2_fpb;
extern	UWORD marker1_fpb;
extern	UWORD marker2_fpb;
extern	UWORD oilpump_fpb;
extern	UWORD silo_fpb;
extern	UWORD sphrtank_fpb;
extern	UWORD grndtank_fpb;
extern	UWORD nukesym_fpb;
extern	UWORD wave_fpb;

extern WORD PDQS_Scale(UWORD *anm_file, WORD anm, WORD frm, WORD xp, WORD yp, UWORD sf);
extern void	DispFrame(UWORD *anim_file, WORD anim, WORD frame,	WORD xp, WORD yp);

/* GEMS Defines: */

#define	MUSIC_GLACIAL	0
#define	MUSIC_OPENING	1
#define	MUSIC_DESERT	2
#define	MUSIC_WIN		4
#define	MUSIC_LOOSE		5
#define	MUSIC_EXTRA		6
#define	MUSIC_FOREST	7
#define	MUSIC_PLAINS	8
#define	MUSIC_TITLE		10
#define	SFX_EXPLOSION	16
#define	SFX_L_MISSLE	17
#define	SFX_BUTTON_ON	18
#define	SFX_CAN_PICKUP	19
#define	SFX_LEVEL_DONE	20
#define	SFX_GAME_OVER	21
#define	SFX_ENTER_LEVL	22
#define	SFX_BUTTON_HIT	23
#define	SFX_R_MISSLE	24
#define	SFX_SHIP_HIT	25
#define	VOICE_CAN_COL	26
#define	VOICE_FUEL_LOW	27
#define	VOICE_GAME_OVR	28
#define	VOICE_LASERS_D	29
#define	VOICE_MISSLESD	30
#define	VOICE_MISSIONS	31
#define	VOICE_NUKERUSH	32
#define	VOICE_RADAR_D	33
#define	VOICE_SHIELD_D	34
#define	VOICE_TANKIN_Z	35
#define	VOICE_ZONE_HIT	36

