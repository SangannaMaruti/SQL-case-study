---#checking data loaded or not---
select * from sys.artist limit 10;
select * from sys.canvas_size limit 10;
select * from sys.image_link limit 10;
select * from sys.museum limit 10;
select * from sys.museum_hours limit 10;
select * from sys.product_size limit 10;
select * from sys.subject limit 10;
select * from sys.work limit 10;

#Checking Count
select count(*) from sys.artist; #421
select count(*) from sys.canvas_size; #200
select count(*) from sys.image_link; #14775
select count(*) from sys.museum; #57
select count(*) from sys.museum_hours; #351
select count(*) from sys.product_size; #110347
select count(*) from sys.subject; #6771
select count(*) from sys.work; #14776

##1. 1) Fetch all the paintings which are not displayed on any museums?
select * from sys.work where museum_id is null;

#2) Are there museuems without any paintings?
select * from sys.museum m
	where not exists (select 1 from sys.work w
					 where w.museum_id=m.museum_id);

#3) How many paintings have an asking price of more than their regular price?
select * from sys.product_size
	where sale_price > regular_price;
    
#4) Identify the paintings whose asking price is less than 50% of its regular price
select * from sys.product_size where sale_price < (regular_price*0.5);

#5) Which canva size costs the most?
select cs.label as canva, ps.sale_price
	from (select *
		  , rank() over(order by sale_price desc) as rnk 
		  from sys.product_size) ps
	join sys.canvas_size cs on cs.size_id=ps.size_id
	where ps.rnk=1;
    
#6) Delete duplicate records from work, product_size, subject and image_link tables
delete from sys.work 
	where artist_id not in (select min(artist_id)
						from sys.work
						group by work_id );

	delete from sys.product_size 
	where ctid not in (select min(ctid)
						from sys.product_size
						group by work_id, size_id );

	delete from sys.subject 
	where ctid not in (select min(ctid)
						from sys.subject
						group by work_id, subject );

	delete from sys.image_link 
	where ctid not in (select min(ctid)
						from sys.image_link
						group by work_id );
                        
#7) Identify the museums with invalid city information in the given dataset
select * from sys.museum where city ='^[0-9]';

#8) Museum_Hours table has 1 invalid entry. Identify it and remove it.
delete from sys.museum_hours 
	where museum_id not in (select min(museum_id)
						from sys.museum_hours
						group by museum_id, day );
                        
#9) Fetch the top 10 most famous painting subject
select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from sys.work w
		join sys.subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;

#10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select * from sys.museum_hours m1
where day='sunday' and exists(
select 1 from sys.museum_hours m2  where m1.museum_id=m2.museum_id and m2.day='Monday');

#11) How many museums are open every single day?
select count(1)
	from (select museum_id, count(1)
		  from sys.museum_hours
		  group by museum_id
		  having count(1) = 7) x;
          
#12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from sys.work w
			join sys.museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join sys.museum m on m.museum_id=x.museum_id
	where x.rnk<=5;
    
#13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from sys.work w
			join sys.artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join sys.artist a on a.artist_id=x.artist_id
	where x.rnk<=5;
    
#14) Display the 3 least popular canva sizes
select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from sys.work w
		join sys.product_size ps on ps.work_id=w.work_id
		join sys.canvas_size cs on cs.size_id = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;
    
#15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
use sys;
select museum_name,state as city,mh.day, mh.open, mh.close, duration
	from (	select m.name as museum_name, m.state, mh.day, mh.open, mh.close
			, to_timestamp(mh.open,'HH:MI AM') 
			, to_timestamp(mh.close,'HH:MI PM') 
			, to_timestamp(mh.close,'HH:MI PM') - to_timestamp(mh.open,'HH:MI AM') as duration
			, rank() over (order by (to_timestamp(mh.close,'HH:MI PM') - to_timestamp(mh.open,'HH:MI AM')) desc) as rnk
			from sys.museum_hours mh
		 	join sys.museum m on m.museum_id=mh.museum_id) x
	where x.rnk=1;

#16) Which museum has the most no of most popular painting style?
with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from sys.work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from sys.work w
			join sys.museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;

#17) Identify the artists whose paintings are displayed in multiple countries
with cte as
		(select distinct a.full_name as artist
		, w.name as painting, m.name as museum
		, m.country
		from work w
		join sys.artist a on a.artist_id=w.artist_id
		join sys.museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;
    
#18) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
with cte_country as 
			(select country, count(1)
			, rank() over(order by count(1) desc) as rnk
			from sys.museum
			group by country),
		cte_city as
			(select city, count(1)
			, rank() over(order by count(1) desc) as rnk
			from sys.museum
			group by city)
	select string_agg(distinct country.country,', '), string_agg(city.city,', ')
	from cte_country country
	cross join cte_city city
	where country.rnk = 1
	and city.rnk = 1;
    
#19) Identify the artist and the museum where the most expensive and least expensive painting is placed. Display the artist name, sale_price, painting name, museum name, museum city and canvas label
with cte as 
		(select *
		, rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
		from sys.product_size )
	select w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join sys.work w on w.work_id=cte.work_id
	join sys.museum m on m.museum_id=w.museum_id
	join sys.artist a on a.artist_id=w.artist_id
	join sys.canvas_size cz on cz.size_id = cte.size_id
	where rnk=1 or rnk_asc=1;
    
#20) Which country has the 5th highest no of paintings?
with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from sys.work w
		join sys.museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;
    
#21) Which are the 3 most popular and 3 least popular painting styles?
with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from sys.work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;

#22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from sys.work w
		join sys.artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join sys.museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	

