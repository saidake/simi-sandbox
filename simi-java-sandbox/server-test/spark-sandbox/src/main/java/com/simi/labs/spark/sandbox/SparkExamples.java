package com.simi.labs.spark.sandbox;

import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.sql.*;
import org.apache.spark.SparkConf;

import java.util.Arrays;
import java.util.List;

public class SparkExamples {

    public static void main(String[] args) {

        // Initialize Spark Context and Spark Session
        SparkConf conf = new SparkConf().setAppName("SparkSandbox").setMaster("local[*]");
        JavaSparkContext sc = new JavaSparkContext(conf);
        SparkSession spark = SparkSession.builder()
                .appName("SparkSandbox")
                .master("local[*]")
                .getOrCreate();

        try {
            exampleRDD(sc);
            exampleDataFrame(spark);
            exampleSQL(spark);
        } finally {
            sc.close();
            spark.close();
        }
    }

    // Example 1: Basic RDD operations
    public static void exampleRDD(JavaSparkContext sc) {
        System.out.println("Running exampleRDD...");

        List<Integer> data = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
        JavaRDD<Integer> rdd = sc.parallelize(data);

        // Filter even numbers and sum them
        int sumEven = rdd.filter(x -> x % 2 == 0).reduce(Integer::sum);
        System.out.println("Sum of even numbers: " + sumEven);

        assert sumEven == 30 : "Sum should be 30";
    }

    // Example 2: Basic DataFrame operations
    public static void exampleDataFrame(SparkSession spark) {
        System.out.println("Running exampleDataFrame...");

        // Create DataFrame from list of tuples
        List<Person> people = Arrays.asList(
                new Person("Alice", 30),
                new Person("Bob", 25),
                new Person("Charlie", 35)
        );

        Dataset<Row> df = spark.createDataFrame(people, Person.class);
        df.show();

        // Filter people older than 28
        Dataset<Row> filtered = df.filter(df.col("age").gt(28));
        filtered.show();

        long count = filtered.count();
        System.out.println("People older than 28: " + count);

        assert count == 2 : "Count should be 2";
    }

    // Example 3: Basic Spark SQL operations
    public static void exampleSQL(SparkSession spark) {
        System.out.println("Running exampleSQL...");

        // Create a DataFrame
        List<Person> people = Arrays.asList(
                new Person("David", 40),
                new Person("Eva", 22),
                new Person("Frank", 29)
        );

        Dataset<Row> df = spark.createDataFrame(people, Person.class);
        df.createOrReplaceTempView("people");

        // Query using Spark SQL
        Dataset<Row> sqlResult = spark.sql("SELECT name, age FROM people WHERE age >= 30");
        sqlResult.show();

        long count = sqlResult.count();
        System.out.println("People aged 30 or older: " + count);

        assert count == 1 : "Count should be 1";
    }

    // Helper POJO class for DataFrame schema
    public static class Person implements java.io.Serializable {
        private String name;
        private int age;

        // Empty constructor for Spark
        public Person() {}

        public Person(String name, int age) {
            this.name = name;
            this.age = age;
        }

        // Getters and setters required for Spark
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public int getAge() { return age; }
        public void setAge(int age) { this.age = age; }
    }
}
