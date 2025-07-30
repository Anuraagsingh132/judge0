FROM judge0/api:1.13.0

EXPOSE 3000

CMD ["./wait-for-it.sh", "db:5432", "--", "./start.sh"]
