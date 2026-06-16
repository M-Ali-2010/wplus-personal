import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Job, JobStatus } from '../entities/job.entity';
import { User } from '../entities/user.entity';
import { AuthService } from '../auth/auth.service';
import { CreateJobDto } from './marketplace.dto';

@Injectable()
export class MarketplaceService {
  constructor(
    @InjectRepository(Job) private jobsRepo: Repository<Job>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    private authService: AuthService,
  ) {}

  async getJobs(category?: string) {
    const jobs = await this.jobsRepo.find({
      where: category ? { status: JobStatus.OPEN, category } : { status: JobStatus.OPEN },
      relations: ['poster'],
      order: { createdAt: 'DESC' },
      take: 50,
    });

    return jobs.map((j) => this.toPublic(j));
  }

  async getJob(id: string) {
    const job = await this.jobsRepo.findOne({ where: { id }, relations: ['poster'] });
    if (!job) throw new NotFoundException('Job not found');
    return this.toPublic(job);
  }

  async createJob(posterId: string, dto: CreateJobDto) {
    const job = this.jobsRepo.create({
      ...dto,
      posterId,
      status: JobStatus.OPEN,
    });
    await this.jobsRepo.save(job);
    const full = await this.jobsRepo.findOne({ where: { id: job.id }, relations: ['poster'] });
    return this.toPublic(full!);
  }

  async applyJob(jobId: string, userId: string, coverLetter?: string) {
    const job = await this.jobsRepo.findOne({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Job not found');
    job.applicantsCount += 1;
    await this.jobsRepo.save(job);
    return { success: true, jobId, userId, coverLetter };
  }

  private toPublic(job: Job) {
    return {
      id: job.id,
      title: job.title,
      description: job.description,
      category: job.category,
      budget: Number(job.budget),
      currency: job.currency,
      tags: job.tags ?? [],
      status: job.status,
      applicantsCount: job.applicantsCount,
      poster: job.poster ? this.authService.toPublicUser(job.poster) : { id: job.posterId },
      createdAt: job.createdAt,
    };
  }
}
