// Default URL for triggering event grid function in the local environment.
// http://localhost:7071/runtime/webhooks/EventGrid?functionName={functionname}
using System;
using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Gif;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Threading.Tasks;

namespace image_processor
{
    public static class thumbnail
    {
        // [FunctionName("thumbnail_blob")]
        // public static async Task Run2(
        //     [BlobTrigger("images/{name}")]Stream myBlob, 
        //     string name, 
        //     ILogger log)
        // {
        //     log.LogInformation($"C# Blob trigger function Processed blob\n Name:{name} \n Size: {myBlob.Length} Bytes");

        //     try
        //     {
        //         await CreateThumbnail(myBlob, name);
        //         log.LogInformation("thubnail created");
        //     }
        //     catch (Exception ex)
        //     {
        //         log.LogError(ex, "creating thumbnail failed");
        //         throw;
        //     }

        // }

        [FunctionName("thumbnail")]
        public static async Task Run1(
            [EventGridTrigger]EventGridEvent eventGridEvent, 
            [Blob("{data.url}", FileAccess.Read)] Stream input,
            ILogger log)
        {
            log.LogInformation(eventGridEvent.Data.ToString());
            try
            {
                var createdEvent = ((JObject)eventGridEvent.Data).ToObject<StorageBlobCreatedEventData>();
                var blobName = new CloudBlob(new Uri(createdEvent.Url)).Name;
                await CreateThumbnail(input, blobName);

                log.LogInformation("thubnail created");
            }
            catch(Exception ex)
            {
                log.LogError(ex, "creating thumbnail failed");
                throw;
            }
        }

        private static async Task CreateThumbnail(Stream input, string outputBlobname)
        {
                var encorder = new JpegEncoder();
                var thumbnailWidth = 256;

                var storageConstr = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
                var storageAccount = CloudStorageAccount.Parse(storageConstr);
                var blobClient = storageAccount.CreateCloudBlobClient();

                var thumbContainerName = Environment.GetEnvironmentVariable("OUTPUT_CONTAINER_NAME");
                var container = blobClient.GetContainerReference(thumbContainerName);
                var outputBlob = container.GetBlockBlobReference(outputBlobname);

                using(var image = Image.Load(input))
                {
                    var thumbnailHeight = thumbnailWidth * image.Height / image.Width;
                    image.Mutate(ctx => ctx.Resize(thumbnailWidth, thumbnailHeight));

                    using(var output = await outputBlob.OpenWriteAsync())
                    {
                        image.Save(output, encorder);
                    }
                }

        }
    }
}
