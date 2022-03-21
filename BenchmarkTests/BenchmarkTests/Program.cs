
using BenchmarkDotNet.Running;
using BenchmarkTests.TestClasses;

Console.WriteLine("Hello, World!");

var summary = BenchmarkRunner.Run<WriteSmallStringToFile>();