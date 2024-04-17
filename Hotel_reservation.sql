#select count(*) from sys.Hotel_Reservations;
select * from sys.Hotel_Reservations limit 10;
#1. Total no of reservations
select count(Booking_ID) as total_reservations from sys.Hotel_Reservations;
#2 Most popular meal plan among guests
select distinct type_of_meal_plan,count(*) as total_count from sys.Hotel_Reservations group by type_of_meal_plan order by total_count desc;
#3 Average price per room for reservations involving children
select avg(avg_price_per_room) from sys.Hotel_Reservations where no_of_children>0;
#4 Reservations made for the year 20XX
select count(Booking_ID) as total_reservations from sys.Hotel_Reservations where extract(year from arrival_date)=2017;
select count(Booking_ID) as total_reservations  from sys.Hotel_Reservations where extract(year from arrival_date)=2018;
#5Most commonly booked room type
select room_type_reserved, count(*) as Total_count from sys.Hotel_Reservations 
group by room_type_reserved order by Total_count desc limit 1;
#6Total no. of reservations fall on a weekend
select count(*) as weekend_reservations from sys.Hotel_Reservations where no_of_weekend_nights > 0;
#7Highest and lowest lead time for reservations
select max(lead_time) as Highest,min(lead_time) as lowest from sys.Hotel_Reservations;
#8Most common market segment type for reservations
select market_segment_type, count(*) as total_count from sys.Hotel_Reservations group by market_segment_type
order by total_count desc limit 1;
#9Reservations having booking status "Confirmed"
select count(*) as booking from sys.Hotel_Reservations where booking_status='not_canceled';
#10. Total number of adults and children across all reservations
select sum(no_of_adults) as adults,sum(no_of_children) as children from sys.Hotel_Reservations;
#11. Average number of weekend nights for reservations involving children
select avg(no_of_weekend_nights) from sys.Hotel_Reservations where no_of_children >0;
#12. Reservations made in each month of the year
select extract(month from arrival_date) as month, count(*) as reservations from sys.Hotel_Reservations 
group by extract(month from arrival_date) order by month;
#13. Average number of nights spent by guests for each room type
select room_type_reserved,avg(no_of_weekend_nights + no_of_week_nights) as no_of_nights from sys.Hotel_Reservations
group by room_type_reserved;
#14. Most common room type, and the average price for that room type (involving children)
select room_type_reserved,avg(avg_price_per_room) from sys.Hotel_Reservations where no_of_children > 0 group by room_type_reserved
order by count(*) desc limit 1;
#15. Market segment type that generates the highest average price per room
select market_segment_type,avg(avg_price_per_room) from sys.Hotel_Reservations group by 1 order by 2 desc limit 1;
