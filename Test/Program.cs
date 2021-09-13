using System;
using System.Diagnostics;
using System.Reflection;
namespace Test
{
    class Program
    {
        static int Main(string[] args)
        {
            string assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version.ToString(); 
            string fileVersion = FileVersionInfo.GetVersionInfo(Assembly.GetExecutingAssembly().Location).FileVersion; 
            string productVersion = FileVersionInfo.GetVersionInfo(Assembly.GetExecutingAssembly().Location).ProductVersion;
            bool versionsCorrect = true;
            if (assemblyVersion == VersionInfo.AssemblyVersion)
                Console.WriteLine($"Assembly Version: {assemblyVersion}");
            else
            {
                versionsCorrect = false;
                Console.WriteLine($"Assembly Version: {assemblyVersion}(Assembly) != {VersionInfo.AssemblyVersion}(Code)");
            }
            if (fileVersion == VersionInfo.FileVersion)
                Console.WriteLine($"File Version: {fileVersion}");
            else
            {
                versionsCorrect = false;
                Console.WriteLine($"File Version: {fileVersion}(Assembly) != {VersionInfo.FileVersion}(Code)");
            }
            if (productVersion == VersionInfo.ProductVersion)
                Console.WriteLine($"Product Version: {productVersion}");
            else
            {
                versionsCorrect = false;
                Console.WriteLine($"Product Version: {productVersion}(Assembly) != {VersionInfo.ProductVersion}(Code)");
            }
            
            return versionsCorrect ? 0 : -1;
        }
    }
}
