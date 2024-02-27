-- Calculate the total number of albums, artists, customers, employees, genres, invoices, invoice lines, media types, playlists, and tracks in the database.
USE chinook;
SELECT COUNT(DISTINCT AlbumId) AS Total_albums
FROM album;

SELECT COUNT(DISTINCT ArtistId) AS Total_artist
FROM artist;

SELECT COUNT(DISTINCT CustomerID) AS Total_customers
FROM customer;

SELECT COUNT(DISTINCT InvoiceId) AS Total_invoices
FROM invoice;

SELECT COUNT(DISTINCT InvoicelineId) AS Total_invoicelines
FROM Invoiceline;

SELECT COUNT(DISTINCT AlbumId) AS Total_albums
FROM album;

SELECT COUNT(DISTINCT MediatypeId) AS Total_mediatypes
FROM mediatype;

SELECT COUNT(DISTINCT PlaylistId) AS Total_playlists
FROM Playlist;

SELECT COUNT(DISTINCT PlaylistId) AS Total_playlists
FROM Playlist;

SELECT COUNT(DISTINCT TrackId) AS Total_playlisttracks
FROM track;

-- Identify the artist with the most albums.

SELECT ar.Name, COUNT(ab.AlbumId) AS Total_Albums
FROM album ab
LEFT JOIN artist ar ON ar.ArtistId = ab.ArtistId
GROUP BY 1
ORDER BY 2 DESC LIMIT 1 ;

-- Determine the total sales revenue from invoices.

SELECT SUM(Total) AS Total_revenue
FROM chinook.invoice;

-- Find the top 5 countries with the highest number of customers.

SELECT Country, COUNT(*) AS Number_of_customers
FROM customer
GROUP BY 1 
ORDER BY 2 DESC LIMIT 5;

-- Calculate the average total purchase amount per customer.

SELECT c.FirstName, c.LastName, ROUND(AVG(i.Total),2) AS AVG_Purchase_Amount
FROM invoice i
LEFT JOIN customer c on i.CustomerId = c.CustomerId
GROUP BY 1,2 
ORDER BY 3 DESC;

-- List the top 5 genres with the highest number of tracks.

SELECT g.Name AS Genre, COUNT(t.TrackId) AS Number_of_tracks
FROM track t
LEFT JOIN genre g ON t.GenreId = g.GenreId
GROUP BY 1 
ORDER BY 2 DESC;

-- Find the genre with the highest total track duration.

SELECT g.Name Genre, t.Milliseconds/3600 AS Duration   
FROM track t
LEFT JOIN genre g ON g.GenreId = t.GenreId
ORDER BY 2 DESC LIMIT 1;
 
-- Calculate the average unit price of tracks for each genre.

SELECT g.Name Genre, ROUND(AVG(UnitPrice),2) AS AVG_Unit_price  
FROM track t
LEFT JOIN genre g ON g.GenreId = t.GenreId
GROUP BY 1
ORDER BY 2 DESC ;

-- Which countries have the most Invoices?

SELECT BillingCountry, COUNT(*) AS Invoices
FROM invoice
GROUP BY BillingCountry
ORDER BY COUNT(*) DESC;

-- Which city has the best customers?

SELECT BillingCity, SUM(Total) AS Invoice_total
FROM invoice
GROUP BY BillingCity
ORDER BY SUM(Total) DESC;

-- 

SELECT c.FirstName, c.LastName, i.CustomerId, SUM(i.Total) AS Invoice_total_$
FROM invoice i
INNER JOIN customer c on c.CustomerId = i.CustomerId
GROUP BY CustomerId
ORDER BY SUM(Total) DESC LIMIT 1;

-- Use your query to return the email, first name, last name, and Genre of all Rock Music listeners. Return your list ordered alphabetically by email address starting with A. Can you find a way to deal with duplicate email addresses so no one receives multiple emails?

SELECT DISTINCT c.FirstName, c.LastName,  c.Email, g.Name 
FROM customer c 
JOIN invoice i ON c.CustomerId = i.CustomerId
JOIN invoiceline il ON i.invoiceId = il.invoiceId
JOIN track t on il.trackId = t.trackId
JOIN genre g on g.genreId = t.genreId
WHERE g.Name = 'Rock'
ORDER BY c.Email;

-- Who is writing the rock music?

SELECT DISTINCT a.Name, g.Name, COUNT(t.trackId) AS No_of_songs
FROM artist a
JOIN album al ON a.artistid = al.artistid
JOIN track t on al.albumId = t.albumId
JOIN genre g on g.genreId = t.genreId
WHERE g.Name = 'Rock'
GROUP BY a.Name, g.Name
ORDER BY COUNT(t.trackId) DESC;

-- First, find which artist has earned the most according to the InvoiceLines? Now use this artist to find which customer spent the most on this artist.

SELECT a.artistid, a.Name, SUM(il.unitprice * il.quantity) AS Total_earned
FROM invoiceline il 
JOIN track t ON il.trackid = t.trackid
JOIN album al ON al.albumid = t.albumid
JOIN artist a ON a.artistid = al.artistid
GROUP BY a.artistid, a.Name
ORDER BY SUM(il.unitprice * il.quantity) DESC LIMIT 1;

SELECT a.name AS artist_name, c.FirstName, c.LastName, SUM(il.Quantity * il.UnitPrice) AS total_Spent
FROM customer c
JOIN invoice i on c.CustomerId = i.CustomerId
JOIN invoiceline il ON i.invoiceId = il.invoiceId
JOIN track t ON il.trackid = t.trackid
JOIN album al ON al.albumid = t.albumid 
JOIN artist a ON a.artistid = al.artistid
WHERE a.artistid = 90
GROUP BY c.FirstName, c.LastName
ORDER BY SUM(i.Total) DESC;

-- We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

SELECT c.country ,g.name ,  COUNT(i.invoiceid) AS no_of_purhcase
FROM customer c
JOIN invoice i on c.CustomerId = i.CustomerId
JOIN invoiceline il ON i.invoiceId = il.invoiceId
JOIN track t ON il.trackid = t.trackid
JOIN genre g ON g.genreid = t.genreid
GROUP BY c.country ,g.name;

WITH CTE AS (SELECT c.country ,g.name ,  COUNT(i.invoiceid) AS no_of_purhcase, Rank() over(PARTITION BY COUNTRY ORDER BY COUNT(i.invoiceid) DESC) AS genre_rnk
FROM customer c
JOIN invoice i on c.CustomerId = i.CustomerId
JOIN invoiceline il ON i.invoiceId = il.invoiceId
JOIN track t ON il.trackid = t.trackid
JOIN genre g ON g.genreid = t.genreid
GROUP BY c.country ,g.name) 
SELECT country, name, no_of_purhcase
FROM CTE 
WHERE genre_rnk = 1;

-- Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH CTE AS (SELECT c.country, c.firstname, c.lastname, SUM(i.total) AS totalspent, RANK() OVER (PARTITION BY country ORDER BY SUM(i.total) DESC) AS cust_rnk
FROM invoice i
JOIN customer c ON c.customerid = i.invoiceid
GROUP BY c.country, c.firstname, c.lastname
ORDER BY SUM(i.total) DESC) 
SELECT country, firstname, lastname, totalspent
FROM CTE 
WHERE cust_rnk = 1;

-- Return all the track names that have a song length longer than the average song length. Though you could perform this with two queries. Imagine you wanted your query to update based on when new data is put in the database. Therefore, you do not want to hard code the average into your query. You only need the Track table to complete this query.

SELECT Name, Milliseconds 
FROM (
	SELECT t.Name, t.Milliseconds, AVG(Milliseconds) OVER () AS Avg_length
	FROM Track t
	ORDER BY t.Milliseconds DESC) a
WHERE Milliseconds > Avg_length;



