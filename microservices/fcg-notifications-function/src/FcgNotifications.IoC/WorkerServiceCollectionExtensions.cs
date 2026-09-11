using FcgNotifications.Application;
using FcgNotifications.Domain;
using FcgNotifications.Domain.Repositories;
using FcgNotifications.Infrastructure.Database;
using FcgNotifications.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FcgNotifications.IoC;

public static class WorkerServiceCollectionExtensions
{
    public static void ConfigureWorkerDependencies(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssemblies(
            typeof(IDomainEntryPoint).Assembly,
            typeof(IApplicationAssembly).Assembly));

        services.AddDbContext<FcgNotificationsDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("Default"),
            npgsql => npgsql.EnableRetryOnFailure()));

        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<IUserRepository, UserRepository>();
    }
}
