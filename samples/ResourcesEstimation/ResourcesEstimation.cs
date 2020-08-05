using System;
using System.Threading.Tasks;
using System.IO;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace QromSample
{
    static class MetricCalculationUtils
    {
        /// <summary>
        /// Returns an instance of QCTraceSimulator configured to collect 
        /// circuit metrics
        /// </summary>
        public static QCTraceSimulator RecommendedConfig()
        {
            // Setup QCTraceSimulator to collect all available metrics
            var config = new QCTraceSimulatorConfiguration
            {
                UseDepthCounter = true,
                UsePrimitiveOperationsCounter = true,
                UseWidthCounter = true,
            };

            // Set up gate times to compute T depth
            config.TraceGateTimes[PrimitiveOperationsGroups.CNOT] = 0;
            config.TraceGateTimes[PrimitiveOperationsGroups.QubitClifford] = 0;
            config.TraceGateTimes[PrimitiveOperationsGroups.Measure] = 0;
            config.TraceGateTimes[PrimitiveOperationsGroups.R] = 0;
            config.TraceGateTimes[PrimitiveOperationsGroups.T] = 1;

            // Create an instance of Quantum Computer Trace Simulator
            return new QCTraceSimulator(config);
        }
    }
    class Driver
    {
        static void Main(string[] args)
        {
            // Get an instance of the appropriately configured QCTraceSimulator
            QCTraceSimulator sim = MetricCalculationUtils.RecommendedConfig();


            var queryAddress = 1;
            var output = QromQuerySample.Run(sim, queryAddress).Result;
            double tCountAll = sim.GetMetric<QromQuerySample>(PrimitiveOperationsGroupsNames.T);
            //double tCount = sim.GetMetric<Intrinsic.CCNOT, QromQuerySample>(PrimitiveOperationsGroupsNames.T);
            File.WriteAllText("test.csv",sim.ToCSV(",")[MetricsCountersNames.primitiveOperationsCounter]);
            //Console.WriteLine(sim.ToCSV());
        }
    }
}

// Using the Resources Estimator
// namespace QromSample
// {
//  class Program
//     {
//         static async Task Main(string[] args)
//         {
//             var rng = new System.Random();
//             var queryAddress = rng.Next(0, 7);
//             var estimator = new ResourcesEstimator();
//             var output = await QromQuerySample.Run(estimator, queryAddress);

//             // Print out a table of required resources, using the
//             // ToTSV method of the ResourcesEstimator.
//             Console.WriteLine(estimator.ToTSV());
//         }
//     }
// }

