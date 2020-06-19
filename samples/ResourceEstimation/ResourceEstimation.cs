using System;
using System.Threading.Tasks;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Core;

namespace implicitQRAM
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var rng = new System.Random();
            var queryAddress = rng.Next(0, 7);
            var estimator = new ResourcesEstimator();
            var output = await TestImplicitQRAM.Run(estimator, queryAddress);

            // Print out a table of required resources, using the
            // ToTSV method of the ResourcesEstimator.
            Console.WriteLine(estimator.ToTSV());
        }
    }
}
