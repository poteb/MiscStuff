using BenchmarkDotNet.Attributes;

namespace BenchmarkTests.TestClasses;


[MemoryDiagnoser]
public class WriteSmallStringToFile
{
    private const string TextToWrite = "The stupid small fox got shot in the head.";
    
    [Benchmark]
    public void WriteAllText()
    {
        File.WriteAllText("WriteAllText.txt", TextToWrite);
    }

    [Benchmark]
    public void StreamWriter()
    {
        using var streamwriter = File.AppendText("StreamWriter.txt");
        streamwriter.WriteLine(TextToWrite);
    }
}