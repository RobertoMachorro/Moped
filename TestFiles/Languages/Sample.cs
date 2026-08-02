// Sample.cs — exercises Moped's C# tokenizer.
using System;
using System.Collections.Generic;
using System.Linq;

namespace Sample
{
	public class Employee
	{
		public string Name { get; set; }
		public decimal Salary { get; set; }

		public Employee(string name, decimal salary)
		{
			Name = name;
			Salary = salary;
		}
	}

	public static class Program
	{
		public static void Main(string[] args)
		{
			var employees = new List<Employee>
			{
				new Employee("Alice", 85000.50m),
				new Employee("Bob", 72000.00m)
			};

			decimal total = employees.Sum(e => e.Salary);
			Console.WriteLine($"Total payroll: {total:C}");

			foreach (var e in employees.Where(e => e.Salary > 75000))
			{
				Console.WriteLine($"{e.Name} earns above average.");
			}
		}
	}
}
