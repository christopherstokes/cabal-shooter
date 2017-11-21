-- title:  Cabal Shooter
-- author: Christopher Stokes
-- desc:   cabal style shooter
-- script: moon

export width=240
export height=136
export tilesize=8
export fontsize=6
export shake=0
export bullets={}
export entities={}

btnAxis=(a,b)->
	if btn(a) and btn(b)
		return 0
	elseif btn(a)
		return -1
	elseif btn(b)
		return 1
	else
		return 0

-- filter(function, table)
-- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
filter=(func, tbl)->
	newtbl= {}
	for i,v in pairs(tbl) do
		if func(v) then
			newtbl[i]=v
	return newtbl

class RectCollider
 new:(x=0,y=0,w=1,h=1)=>
  @x=x
  @y=y
  @w=w
  @h=h

 draw:(col=8)=>
  rectb(@x,@y,@w,@h,col)

 collide:(B)=>
  if @x>(B.x+B.w) or (@x+@w-1)<B.x or @y>(B.y+B.h) or (@y+@h-1)<B.y
   return false
  else
   return true

class CircCollider
 new:(x=0,y=0,r=1)=>
  @x=x
  @y=y
  @r=r

 draw:(col=8)=>
  circb(@x,@y,@r,col)

 collide:(B)=>
  d=(@x-B.x)^2+(@y-B.y)^2
  r=(@r+B.r)^2

  if @x>=(B.x-B.r) and @y>=(B.y-B.r)
   r=(@r+B.r+1)^2

  if d>r
   return false
  else
   return true


class Particle
	new:(x=0,y=0,rng=2,dur=30)=>
		@x=x
		@y=y
		@rng=rng
		@dur=dur


class Animation
	new:(frames={},delay=10,loop=true)=>
		@frames=frames
		@delay=delay
		@loop=loop
		@cf=1
		@t=0
	
	update:(sprt)=>
		sprt.id=@frames[@cf]
		if @t>=@delay
			if (@cf == #@frames and @loop==true) then @cf = 1
			else @cf+=1
			@t=0
		
		@t+=1


class Spr
	new:(id=1,w=1,h=1,alpha=0,scale=1,flip=0,rotate=0)=>
		@id=id
		@w=w
		@h=h
		@alpha=alpha
		@scale=scale
		@flip=flip
		@rotate=rotate

	draw:(x,y)=>
		spr(@id,x,y,@alpha,@scale,@flip,@rotate,@w,@h)

class Entity
	new:(x=0,y=0,sprt,w=8,h=8,health=15,yChange=0,xChange=0)=>
		@x=x
		@y=y
		@sprt=sprt
		@w=w
		@h=h
		@health=health
		@yChange=yChange
		@xChange=xChange
		@hitbox=RectCollider(x+1,y+1,w-2,h-2)
		@animation
		@t=0

	update:=>
		@t+=1
		@y+=@yChange
		@x+=@xChange
		@hitbox.x=@x+1
		@hitbox.y=@y+1
		--@hitbox\draw!
		for b=#bullets,1,-1
			if (@hitbox\collide(bullets[b]))
				@health-=1
				shake=1
				table.remove(bullets,b)


class Bullet
	new:(x=0,y=0,r=1,w=1,h=1)=>
		@x=x
		@y=y
		@r=r
		@w=w
		@h=h
		@t=0
		@col=6

	update:=>
		@t+=1
		if @t>5
			@col=13
		if @t>10
			@col=15
			@r-=0.1

	draw:=>
		circ(@x,@y,@r,@col)


class Crosshairs
	new:(x=0,y=0,r=6)=>
		@x=x
		@y=y
		@r=r
		@spd=10

	shoot:=>
		sfx(0,G3)
		b=Bullet(@x,@y)
		table.insert(bullets,b)

	draw:=>
		circb(@x,@y,@r/2,15)
		line(@x,(@y+@r/2)-1,@x,@y+@r,15)
		line(@x,(@y-@r/2)+1,@x,@y-@r,15)
		line((@x+@r/2)-1,@y,@x+@r,@y,15)
		line((@x-@r/2)+1,@y,@x-@r,@y,15)


---------Game Loop Code-----------
export t=0

playersp=Spr(16,2,2,0,2)
playerRunAnim=Animation({16,18,20,22,24,26,28,30},4)
playerShootAnim=Animation({48,50})
player=Entity(width/2,height-32,playersp,16,16)
player.animation=playerShootAnim

ch=Crosshairs(width/2,height/2)


export TIC=->
	--update

	if ch.y < ch.r then ch.y = ch.r
	if ch.y > height-ch.r then ch.y = height-ch.r
	if ch.x < ch.r then ch.x = ch.r
	if ch.x > width-ch.r then ch.x = width-ch.r

	if player.x < 0 then player.x=0
	if player.x > width-32 then player.x=width-32

	if btn(4) -- z button
		-- crosshair
		ch.y+=btnAxis(0,1) -- movement directions up and down
		ch.x+=btnAxis(2,3) -- movement directions left and right
		if t%ch.spd==1 then	ch\shoot!
		-- player
		player.animation = playerShootAnim
		if ch.x > player.x+16 then player.sprt.flip=1
		else player.sprt.flip=0
	else
		player.x+=btnAxis(2,3)*1.3
		player.animation = playerShootAnim
		if (btn(2))
			player.animation = playerRunAnim
			player.sprt.flip = 1
		if (btn(3))
			player.animation = playerRunAnim
			player.sprt.flip=0
	if btnp(5) then return -- x button
	if btnp(7) then return -- s button
	if btnp(6) then return -- a button

	if shake>0
		d=4
		poke(0x3FF9,math.random(-d,d))
		poke(0x3FF9+1,math.random(-d,d))
		shake=shake-1
		if shake==0 then memset(0x3FF9,0,2)

	--draw
	cls(0)

	player.animation\update(player.sprt)
	player.sprt\draw(player.x,player.y)
	player\update!
	ch\draw!

	for j=#bullets,1,-1
		bullets[j]\draw!
		bullets[j]\update!
		if bullets[j].t>15 then table.remove(bullets,j)

	print("bullets: "..#bullets,0,0,6)
	print("entity total: "..#entities,0,height-6,6)
	t+=1
